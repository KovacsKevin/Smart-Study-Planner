//
//  NotificationsViewModel.swift
//  Smart Study Planner
//

import SwiftUI
import SwiftData
import UserNotifications

@MainActor
@Observable
final class NotificationsViewModel {

    // MARK: Dependencies
    private var modelContext: ModelContext

    // MARK: - UserDefaults kulcsok
    private enum UDKey {
        static let weeklyEnabled   = "notif_weekly_enabled"
        static let dailyEnabled    = "notif_daily_enabled"
        static let examDays        = "notif_exam_days"
        static let dailyTime       = "notif_daily_time"
        static let weeklyTime      = "notif_weekly_time"
        static let customTimes     = "notif_custom_exam_times" // JSON: [String: Double]
    }

    // MARK: - Segédfüggvények a perzisztenciához
    private static func loadDate(key: String, defaultHour: Int, defaultMinute: Int) -> Date {
        if let stored = UserDefaults.standard.object(forKey: key) as? Date { return stored }
        return Calendar.current.date(from: DateComponents(hour: defaultHour, minute: defaultMinute)) ?? Date()
    }

    private static func loadCustomTimes() -> [UUID: Date] {
        guard
            let data = UserDefaults.standard.data(forKey: UDKey.customTimes),
            let dict = try? JSONDecoder().decode([String: Double].self, from: data)
        else { return [:] }
        return Dictionary(uniqueKeysWithValues: dict.compactMap { key, value in
            guard let uuid = UUID(uuidString: key) else { return nil }
            return (uuid, Date(timeIntervalSince1970: value))
        })
    }

    private func saveCustomTimes() {
        let dict = Dictionary(uniqueKeysWithValues:
            customExamReminderTimes.map { ($0.key.uuidString, $0.value.timeIntervalSince1970) }
        )
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: UDKey.customTimes)
        }
    }

    // MARK: - Beállítások (automatikus mentéssel)
    var weeklyReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(weeklyReminderEnabled, forKey: UDKey.weeklyEnabled)
            scheduleWeeklyReminderIfNeeded()
        }
    }
    var dailyReminderEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyReminderEnabled, forKey: UDKey.dailyEnabled)
            scheduleDailyReminderIfNeeded()
        }
    }
    var examReminderDays: Int {
        didSet {
            UserDefaults.standard.set(examReminderDays, forKey: UDKey.examDays)
            rescheduleAllExamReminders()
        }
    }
    var dailyReminderTime: Date {
        didSet {
            UserDefaults.standard.set(dailyReminderTime, forKey: UDKey.dailyTime)
            scheduleDailyReminderIfNeeded()
            rescheduleAllExamReminders()
        }
    }
    var weeklyReminderTime: Date {
        didSet {
            UserDefaults.standard.set(weeklyReminderTime, forKey: UDKey.weeklyTime)
            scheduleWeeklyReminderIfNeeded()
        }
    }
    var customExamReminderTimes: [UUID: Date] {
        didSet {
            saveCustomTimes()
            rescheduleAllExamReminders()
        }
    }

    // MARK: Vizsgák
    var exams: [Exam] = []

    // MARK: Engedély
    var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    // MARK: Init – értékek betöltése UserDefaults-ból
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        let ud = UserDefaults.standard

        weeklyReminderEnabled   = ud.object(forKey: UDKey.weeklyEnabled) as? Bool ?? true
        dailyReminderEnabled    = ud.object(forKey: UDKey.dailyEnabled)  as? Bool ?? true
        examReminderDays        = ud.object(forKey: UDKey.examDays)      as? Int  ?? 7
        dailyReminderTime       = Self.loadDate(key: UDKey.dailyTime,  defaultHour: 9, defaultMinute: 0)
        weeklyReminderTime      = Self.loadDate(key: UDKey.weeklyTime, defaultHour: 8, defaultMinute: 0)
        customExamReminderTimes = Self.loadCustomTimes()

        fetchExams()
        Task { await checkAuthorizationStatus() }
    }

    // MARK: - Fetch

    func fetchExams() {
        let descriptor = FetchDescriptor<Exam>(sortBy: [SortDescriptor(\.date)])
        exams = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Computed

    var upcomingWithReminders: [Exam] {
        exams.filter { !$0.isCompleted && $0.daysUntil >= 0 && $0.daysUntil <= 14 }
    }

    /// Az a nap, amikor az emlékeztető kimegy (examReminderDays nappal korábban)
    func reminderDate(for exam: Exam) -> Date {
        Calendar.current.date(byAdding: .day, value: -examReminderDays, to: exam.date) ?? exam.date
    }

    /// Az az IDŐPONT, amit a felhasználó beállított erre a vizsgára (vagy alapértelmezett)
    func reminderTime(for exam: Exam) -> Date {
        customExamReminderTimes[exam.id] ?? dailyReminderTime
    }

    /// A teljes dátum+idő, amikor a push kimegy
    func reminderDateTime(for exam: Exam) -> Date {
        let day = reminderDate(for: exam)
        let time = reminderTime(for: exam)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        return Calendar.current.date(
            bySettingHour: timeComponents.hour ?? 9,
            minute: timeComponents.minute ?? 0,
            second: 0,
            of: day
        ) ?? day
    }

    func reminderDateString(for exam: Exam) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: reminderDateTime(for: exam))
    }

    func urgencyColor(for exam: Exam) -> Color {
        switch exam.daysUntil {
        case ..<1:  return .red
        case 1...3: return .orange
        default:    return .indigo
        }
    }

    var footerText: String {
        "Az értesítések \(examReminderDays) nappal a vizsga előtt lesznek kiküldve."
    }

    // MARK: - Engedélykérés

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            notificationAuthStatus = settings.authorizationStatus
            if settings.authorizationStatus == .authorized {
                rescheduleAllExamReminders()
            }
            return
        }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            notificationAuthStatus = granted ? .authorized : .denied
            if granted {
                rescheduleAllExamReminders()
                scheduleWeeklyReminderIfNeeded()
                scheduleDailyReminderIfNeeded()
            }
        } catch {
            print("Értesítés engedély hiba: \(error)")
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationAuthStatus = settings.authorizationStatus
    }

    var isAuthorized: Bool { notificationAuthStatus == .authorized }

    // MARK: - Ütemezés

    func rescheduleAllExamReminders() {
        guard isAuthorized else { return }
        let center = UNUserNotificationCenter.current()
        let ids = exams.map { examNotificationID(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        for exam in exams where !exam.isCompleted {
            scheduleExamReminder(for: exam)
        }
    }

    func scheduleExamReminder(for exam: Exam) {
        guard isAuthorized else { return }
        let triggerDateTime = reminderDateTime(for: exam)
        guard triggerDateTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "📚 Közelgő vizsga"
        content.body  = "\(exam.subject) – még \(exam.daysUntil) nap van hátra!"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDateTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: examNotificationID(for: exam),
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Ütemezési hiba (\(exam.subject)): \(error)") }
        }
    }

    private func scheduleWeeklyReminderIfNeeded() {
        guard isAuthorized else { return }
        let center = UNUserNotificationCenter.current()
        let id = "weekly_summary"

        if weeklyReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "📅 Heti összesítő"
            content.body  = "Nézd meg a heti vizsgáidat és tervezd meg a tanulást!"
            content.sound = .default

            let timeComps = Calendar.current.dateComponents([.hour, .minute], from: weeklyReminderTime)
            var components = DateComponents()
            components.weekday = 2 // hétfő
            components.hour    = timeComps.hour
            components.minute  = timeComps.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [id])
        }
    }

    private func scheduleDailyReminderIfNeeded() {
        guard isAuthorized else { return }
        let center = UNUserNotificationCenter.current()
        let id = "daily_reminder"

        if dailyReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "🔔 Napi emlékeztető"
            content.body  = "Ne feledd rögzíteni a mai tanulási naplót!"
            content.sound = .default

            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: dailyReminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [id])
        }
    }

    private func examNotificationID(for exam: Exam) -> String {
        "exam_reminder_\(exam.id.uuidString)"
    }

    // MARK: - Tesztelés (fejlesztés közbeni gyors teszt!)
    /// Hívd meg egy gombból, és 10 másodperc múlva kapsz egy teszt-értesítést.
    func scheduleTestNotification() {
        guard isAuthorized else {
            Task { await requestAuthorizationIfNeeded() }
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "✅ Teszt értesítés"
        content.body  = "Az értesítések működnek! Ez 10 másodperccel ezelőtt lett ütemezve."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("Teszt értesítés hiba: \(error)") }
            else { print("✅ Teszt értesítés ütemezve – 10 mp múlva érkezik (küld az appot háttérbe!)") }
        }
    }
}
