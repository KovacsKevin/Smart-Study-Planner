//
//  NotificationsView.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//

import SwiftUI
import SwiftData

struct NotificationsView: View {
    @Query(sort: \Exam.date) private var exams: [Exam]
    
    @State private var weeklyReminderEnabled = true
    @State private var dailyReminderEnabled = true
    @State private var examReminderDays = 7
    @State private var reminderTime = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    private var upcomingWithReminders: [Exam] {
        exams.filter { !$0.isCompleted && $0.daysUntil >= 0 && $0.daysUntil <= 14 }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // General settings section
                Section {
                    Toggle(isOn: $weeklyReminderEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Heti összesítő")
                                    .font(.body)
                                Text("Hétfőn reggel: a hét vizsgái és heti terv")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundStyle(.indigo)
                        }
                    }
                    
                    Toggle(isOn: $dailyReminderEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Napi emlékeztető")
                                    .font(.body)
                                Text("A mai nap vizsgái és tanulási napló")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bell.badge")
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    if dailyReminderEnabled {
                        DatePicker("Emlékeztető ideje", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .environment(\.locale, Locale(identifier: "hu_HU"))
                    }
                } header: {
                    Text("Általános beállítások")
                }
                
                // Exam reminder lead time
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Vizsga előtt \(examReminderDays) nappal")
                                .font(.body)
                            Spacer()
                            Text("\(examReminderDays) nap")
                                .font(.subheadline)
                                .foregroundStyle(.indigo)
                                .fontWeight(.semibold)
                        }
                        Slider(value: Binding(
                            get: { Double(examReminderDays) },
                            set: { examReminderDays = Int($0) }
                        ), in: 1...14, step: 1)
                        .accentColor(.indigo)
                        HStack {
                            Text("1 nap")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("2 hét")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Vizsga-emlékeztető")
                } footer: {
                    Text("Az alkalmazás automatikusan küld értesítést minden közelgő vizsgáról \(examReminderDays) nappal korábban.")
                }
                
                // Upcoming reminders preview
                if !upcomingWithReminders.isEmpty {
                    Section {
                        ForEach(upcomingWithReminders) { exam in
                            ScheduledReminderRow(exam: exam, leadDays: examReminderDays)
                        }
                    } header: {
                        Text("Beütemezett értesítések")
                    } footer: {
                        Text("Az értesítések \(examReminderDays) nappal a vizsga előtt lesznek kiküldve.")
                    }
                }
                
                // Tips section
                Section {
                    NotificationTipRow(
                        icon: "lightbulb.fill",
                        iconColor: .yellow,
                        title: "Okos emlékeztetők",
                        description: "Az alkalmazás a vizsga típusa és prioritása alapján állítja be az emlékeztetők intenzitását."
                    )
                    NotificationTipRow(
                        icon: "iphone",
                        iconColor: .blue,
                        title: "Widget támogatás",
                        description: "Add hozzá a kezdőképernyő widgetet a következő vizsgák gyors eléréséhez."
                    )
                } header: {
                    Text("Tippek")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Értesítések")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Scheduled Reminder Row
struct ScheduledReminderRow: View {
    let exam: Exam
    let leadDays: Int
    
    private var reminderDate: Date {
        Calendar.current.date(byAdding: .day, value: -leadDays, to: exam.date) ?? exam.date
    }
    
    private var reminderDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateStyle = .medium
        return f.string(from: reminderDate)
    }
    
    private var urgencyColor: Color {
        switch exam.daysUntil {
        case ..<1: return .red
        case 1...3: return .orange
        default: return .indigo
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(urgencyColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: "bell.fill")
                    .foregroundStyle(urgencyColor)
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(exam.subject)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                HStack(spacing: 4) {
                    Image(systemName: "bell")
                        .font(.caption2)
                    Text("Emlékeztető: \(reminderDateString)")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(exam.urgencyLevel)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(urgencyColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(urgencyColor.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Notification Tip Row
struct NotificationTipRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .font(.body)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview
#Preview {
    NotificationsView()
        .modelContainer(for: [Exam.self, DailyNote.self], inMemory: true)
}
