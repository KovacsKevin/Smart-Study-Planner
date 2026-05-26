//
//  NotificationsView.swift
//  Smart Study Planner
//

import SwiftUI
import SwiftData

struct NotificationsView: View {
    @Environment(\.modelContext) private var modelContext

    // ViewModel – ez tartalmaz MINDEN logikát
    @State private var vm: NotificationsViewModel?

    var body: some View {
        Group {
            if let vm {
                NotificationsContentView(vm: vm)
            } else {
                ProgressView()
            }
        }
        .task {
            // ViewModel létrehozása és engedélykérés
            let newVM = NotificationsViewModel(modelContext: modelContext)
            await newVM.requestAuthorizationIfNeeded()
            vm = newVM
        }
    }
}

// MARK: - Fő tartalom (külön view, hogy a vm mindig létezzen)
private struct NotificationsContentView: View {
    @Bindable var vm: NotificationsViewModel

    var body: some View {
        NavigationStack {
            List {
                // MARK: Engedély banner (ha nincs megadva)
                if !vm.isAuthorized {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "bell.slash.fill")
                                .foregroundStyle(.red)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Értesítések letiltva")
                                    .font(.subheadline).fontWeight(.semibold)
                                Text("Az alkalmazásnak nincs engedélye értesítések küldésére. Engedélyezd a Beállításokban.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)

                        Button("Beállítások megnyitása") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundStyle(.indigo)
                    }
                }

                // MARK: Általános beállítások
                Section {
                    Toggle(isOn: $vm.weeklyReminderEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Heti összesítő")
                                Text("Minden hétfőn a beállított időben")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "calendar.badge.clock").foregroundStyle(.indigo)
                        }
                    }

                    if vm.weeklyReminderEnabled {
                        DatePicker(
                            "Heti emlékeztető ideje",
                            selection: $vm.weeklyReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .environment(\.locale, Locale(identifier: "hu_HU"))
                    }

                    Toggle(isOn: $vm.dailyReminderEnabled) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Napi emlékeztető")
                                Text("Tanulási napló rögzítése")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "bell.badge").foregroundStyle(.orange)
                        }
                    }

                    if vm.dailyReminderEnabled {
                        DatePicker(
                            "Napi emlékeztető ideje",
                            selection: $vm.dailyReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .environment(\.locale, Locale(identifier: "hu_HU"))
                    }
                } header: {
                    Text("Általános beállítások")
                }

                // MARK: Vizsga-emlékeztető előre hozása
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Értesítés ideje")
                            Spacer()
                            Text("\(vm.examReminderDays) nappal korábban")
                                .font(.subheadline).foregroundStyle(.indigo).fontWeight(.semibold)
                        }
                        Slider(
                            value: Binding(
                                get: { Double(vm.examReminderDays) },
                                set: { vm.examReminderDays = Int($0) }
                            ),
                            in: 1...14, step: 1
                        )
                        .accentColor(.indigo)
                        HStack {
                            Text("1 nap").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text("2 hét").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)

                    // Alapértelmezett időpont minden vizsgához (ha nincs egyedi)
                    DatePicker(
                        "Alapértelmezett időpont",
                        selection: $vm.dailyReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .environment(\.locale, Locale(identifier: "hu_HU"))

                } header: {
                    Text("Vizsga-emlékeztető")
                } footer: {
                    Text("Az értesítések \(vm.examReminderDays) nappal a vizsga előtt, a beállított időpontban mennek ki.")
                }

                // MARK: Beütemezett értesítések (egyedi időpont per vizsga)
                if !vm.upcomingWithReminders.isEmpty {
                    Section {
                        ForEach(vm.upcomingWithReminders) { exam in
                            ScheduledReminderRow(
                                exam: exam,
                                reminderDateTime: vm.reminderDateTime(for: exam),
                                customTime: Binding(
                                    get: { vm.customExamReminderTimes[exam.id] ?? vm.dailyReminderTime },
                                    set: { vm.customExamReminderTimes[exam.id] = $0 }
                                ),
                                urgencyColor: vm.urgencyColor(for: exam)
                            )
                        }
                    } header: {
                        Text("Beütemezett értesítések")
                    } footer: {
                        Text("Minden vizsgához egyedi időpontot is beállíthatsz.")
                    }
                }

                // MARK: Teszt gomb (fejlesztéshez, kivehetod élesben)
                #if DEBUG
                Section {
                    Button {
                        vm.scheduleTestNotification()
                    } label: {
                        Label("Teszt értesítés (10 mp)", systemImage: "bell.and.waves.left.and.right")
                            .foregroundStyle(.indigo)
                    }
                } header: {
                    Text("Fejlesztői eszközök")
                } footer: {
                    Text("Nyomd meg, majd küldd háttérbe az appot. 10 másodperc múlva megérkezik a teszt értesítés.")
                }
                #endif

                // MARK: Tippek
                Section {
                    NotificationTipRow(
                        icon: "lightbulb.fill", iconColor: .yellow,
                        title: "Okos emlékeztetők",
                        description: "Az alkalmazás a vizsga prioritása alapján állítja be az emlékeztetők intenzitását."
                    )
                    NotificationTipRow(
                        icon: "iphone", iconColor: .blue,
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

// MARK: - Scheduled Reminder Row (egyedi időpont beállítással)
struct ScheduledReminderRow: View {
    let exam: Exam
    let reminderDateTime: Date
    @Binding var customTime: Date
    let urgencyColor: Color

    @State private var showTimePicker = false

    private var reminderDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: reminderDateTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(urgencyColor.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "bell.fill")
                        .foregroundStyle(urgencyColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(exam.subject)
                        .font(.subheadline).fontWeight(.semibold)
                    HStack(spacing: 4) {
                        Image(systemName: "bell").font(.caption2)
                        Text(reminderDateString)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Egyedi időpont gomb
                Button {
                    showTimePicker.toggle()
                } label: {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundStyle(showTimePicker ? urgencyColor : .secondary)
                }
                .buttonStyle(.plain)

                Text(exam.urgencyLevel)
                    .font(.caption2).fontWeight(.medium)
                    .foregroundStyle(urgencyColor)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(urgencyColor.opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.vertical, 2)

            // Kinyíló egyedi időpont-választó
            if showTimePicker {
                Divider().padding(.vertical, 4)
                HStack {
                    Text("Egyedi időpont:")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    DatePicker(
                        "",
                        selection: $customTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "hu_HU"))
                }
                .padding(.bottom, 4)
            }
        }
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
                Image(systemName: icon).foregroundStyle(iconColor)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline).fontWeight(.semibold)
                Text(description).font(.caption).foregroundStyle(.secondary)
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
