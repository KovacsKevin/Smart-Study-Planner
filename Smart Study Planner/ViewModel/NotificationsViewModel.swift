//
//  NotificationsViewModel.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//

import SwiftUI
import SwiftData
import UserNotifications

@MainActor
@Observable
final class NotificationsViewModel {

    // MARK: Dependencies
    private var modelContext: ModelContext

    // MARK: State – beállítások
    var weeklyReminderEnabled: Bool = true {
        didSet { scheduleWeeklyReminderIfNeeded() }
    }
    var dailyReminderEnabled: Bool = true {
        didSet { scheduleDailyReminderIfNeeded() }
    }
    var examReminderDays: Int = 7 {
        didSet { rescheduleAllExamReminders() }
    }
    var reminderTime: Date = Calendar.current.date(
        from: DateComponents(hour: 9, minute: 0)
    ) ?? Date() {
        didSet { rescheduleAllExamReminders() }
    }

    // MARK: State – vizsgák
    var exams: [Exam] = []

    // MARK: State – engedély
    var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    // MARK: Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchExams()
        Task { await checkAuthorizationStatus() }
    }

    // MARK: - Fetch

    func fetchExams() {
        let descriptor = FetchDescriptor<Exam>(
            sortBy: [SortDescriptor(\.date)]
        )
        exams = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Computed: beütemezett értesítések listája (preview)

    /// Vizsgák amelyekhez érdemes értesítőt mutatni: nem teljesített, 0–14 napon belül
    var upcomingWithReminders: [Exam] {
        exams.filter { !$0.isCompleted && $0.daysUntil >= 0 && $0.daysUntil <= 14 }
    }

    /// Egy adott vizsgához mikor megy ki az emlékeztető
    func reminderDate(for exam: Exam) -> Date {
        Calendar.current.date(byAdding: .day, value: -examReminderDays, to: exam.date) ?? exam.date
    }

    func reminderDateString(for exam: Exam) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateStyle = .medium
        return f.string(from: reminderDate(for: exam))
    }

    /// Footer szöveg dinamikusan
    var footerText: String {
        "Az értesítések \(examReminderDays) nappal a vizsga előtt lesznek kiküldve."
    }

    var sliderFooterText: String {
        "Az alkalmazás automatikusan küld értesítést minden közelgő vizsgáról \(examReminderDays) nappal korábban."
    }

    // MARK: - Urgency color (ScheduledReminderRow-hoz)

    func urgencyColor(for exam: Exam) -> Color {
        switch exam.daysUntil {
        case ..<1:  return .red
        case 1...3: return .orange
        default:    return .indigo
        }
    }

    // MARK: - UNUserNotifications engedélykérés

    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else {
            notificationAuthStatus = settings.authorizationStatus
            return
        }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            notificationAuthStatus = granted ? .authorized : .denied
            if granted { rescheduleAllExamReminders() }
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

    /// Összes vizsga-emlékeztető újraütemezése (pl. examReminderDays vagy reminderTime változásakor)
    func rescheduleAllExamReminders() {
        guard isAuthorized else { return }
        let center = UNUserNotificationCenter.current()

        // Töröljük a régi vizsga-értesítőket
        let ids = exams.map { examNotificationID(for: $0) }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        // Ütemezzük az újakat
        for exam in exams where !exam.isCompleted {
            scheduleExamReminder(for: exam)
        }
    }

    func scheduleExamReminder(for exam: Exam) {
        guard isAuthorized else { return }
        let triggerDate = reminderDate(for: exam)
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "📚 Közelgő vizsga"
        content.body  = "\(exam.subject) – még \(exam.daysUntil) nap van hátra!"
        content.sound = .default

        var components = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        components.hour   = timeComponents.hour
        components.minute = timeComponents.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: examNotificationID(for: exam),
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
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

            // Minden hétfőn reggel 8-kor
            var components = DateComponents()
            components.weekday = 2 // hétfő
            components.hour    = 8
            components.minute  = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
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

            let timeComponents = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: true)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [id])
        }
    }

    private func examNotificationID(for exam: Exam) -> String {
        "exam_reminder_\(exam.id.uuidString)"
    }
}
