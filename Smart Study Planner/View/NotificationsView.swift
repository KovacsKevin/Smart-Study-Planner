import SwiftUI
import SwiftData

struct NotificationsView: View {
    @Environment(\.modelContext) private var modelContext
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
            let newVM = NotificationsViewModel(modelContext: modelContext)
            await newVM.requestAuthorizationIfNeeded()
            vm = newVM
        }
    }
}

private struct NotificationsContentView: View {
    @Bindable var vm: NotificationsViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationStack {
            if horizontalSizeClass == .regular {
                // iPad layout – kétoszlopos
                ScrollView {
                    VStack(spacing: 24) {
                        // Engedély banner
                        if !vm.isAuthorized {
                            authBanner
                                .padding(.horizontal, 32)
                                .padding(.top, 8)
                        }

                        HStack(alignment: .top, spacing: 20) {
                            // Bal oszlop
                            VStack(spacing: 16) {
                                iPadNotifSection(title: "Általános beállítások") {
                                    VStack(spacing: 12) {
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
                                            DatePicker("Heti emlékeztető ideje", selection: $vm.weeklyReminderTime, displayedComponents: .hourAndMinute)
                                                .environment(\.locale, Locale(identifier: "hu_HU"))
                                        }
                                        Divider()
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
                                            DatePicker("Napi emlékeztető ideje", selection: $vm.dailyReminderTime, displayedComponents: .hourAndMinute)
                                                .environment(\.locale, Locale(identifier: "hu_HU"))
                                        }
                                    }
                                }

                                iPadNotifSection(title: "Tippek") {
                                    VStack(spacing: 12) {
                                        NotificationTipRow(
                                            icon: "lightbulb.fill", iconColor: .yellow,
                                            title: "Okos emlékeztetők",
                                            description: "Az alkalmazás a vizsga prioritása alapján állítja be az emlékeztetők intenzitását."
                                        )
                                        Divider()
                                        NotificationTipRow(
                                            icon: "iphone", iconColor: .blue,
                                            title: "Widget támogatás",
                                            description: "Add hozzá a kezdőképernyő widgetet a következő vizsgák gyors eléréséhez."
                                        )
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)

                            // Jobb oszlop
                            VStack(spacing: 16) {
                                iPadNotifSection(title: "Vizsga-emlékeztető") {
                                    VStack(alignment: .leading, spacing: 12) {
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
                                        Divider()
                                        DatePicker("Alapértelmezett időpont", selection: $vm.dailyReminderTime, displayedComponents: .hourAndMinute)
                                            .environment(\.locale, Locale(identifier: "hu_HU"))
                                        Text("Az értesítések \(vm.examReminderDays) nappal a vizsga előtt, a beállított időpontban mennek ki.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                if !vm.upcomingWithReminders.isEmpty {
                                    iPadNotifSection(title: "Beütemezett értesítések") {
                                        VStack(spacing: 8) {
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
                                                if exam.id != vm.upcomingWithReminders.last?.id {
                                                    Divider()
                                                }
                                            }
                                        }
                                    }
                                }

                                #if DEBUG
                                iPadNotifSection(title: "Fejlesztői eszközök") {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Button {
                                            vm.scheduleTestNotification()
                                        } label: {
                                            Label("Teszt értesítés (10 mp)", systemImage: "bell.and.waves.left.and.right")
                                                .foregroundStyle(.indigo)
                                        }
                                        Text("Nyomd meg, majd küldd háttérbe az appot. 10 másodperc múlva megérkezik a teszt értesítés.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                #endif
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)
                    }
                }
                .background(Color(.systemGroupedBackground))
                .navigationTitle("Értesítések")
                .navigationBarTitleDisplayMode(.large)

            } else {
                // iPhone layout – eredeti
                List {
                    if !vm.isAuthorized {
                        Section {
                            authBanner
                            Button("Beállítások megnyitása") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .foregroundStyle(.indigo)
                        }
                    }

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
                            DatePicker("Heti emlékeztető ideje", selection: $vm.weeklyReminderTime, displayedComponents: .hourAndMinute)
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
                            DatePicker("Napi emlékeztető ideje", selection: $vm.dailyReminderTime, displayedComponents: .hourAndMinute)
                                .environment(\.locale, Locale(identifier: "hu_HU"))
                        }
                    } header: { Text("Általános beállítások") }

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
                        DatePicker("Alapértelmezett időpont", selection: $vm.dailyReminderTime, displayedComponents: .hourAndMinute)
                            .environment(\.locale, Locale(identifier: "hu_HU"))
                    } header: { Text("Vizsga-emlékeztető") }
                    footer: { Text("Az értesítések \(vm.examReminderDays) nappal a vizsga előtt, a beállított időpontban mennek ki.") }

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
                        } header: { Text("Beütemezett értesítések") }
                        footer: { Text("Minden vizsgához egyedi időpontot is beállíthatsz.") }
                    }

                    #if DEBUG
                    Section {
                        Button {
                            vm.scheduleTestNotification()
                        } label: {
                            Label("Teszt értesítés (10 mp)", systemImage: "bell.and.waves.left.and.right")
                                .foregroundStyle(.indigo)
                        }
                    } header: { Text("Fejlesztői eszközök") }
                    footer: { Text("Nyomd meg, majd küldd háttérbe az appot. 10 másodperc múlva megérkezik a teszt értesítés.") }
                    #endif

                    Section {
                        NotificationTipRow(icon: "lightbulb.fill", iconColor: .yellow, title: "Okos emlékeztetők", description: "Az alkalmazás a vizsga prioritása alapján állítja be az emlékeztetők intenzitását.")
                        NotificationTipRow(icon: "iphone", iconColor: .blue, title: "Widget támogatás", description: "Add hozzá a kezdőképernyő widgetet a következő vizsgák gyors eléréséhez.")
                    } header: { Text("Tippek") }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Értesítések")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }

    
    private var authBanner: some View {
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
    }
}


private struct iPadNotifSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
    }
}


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
                        Text(reminderDateString).font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                Spacer()
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

            if showTimePicker {
                Divider().padding(.vertical, 4)
                HStack {
                    Text("Egyedi időpont:")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: $customTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "hu_HU"))
                }
                .padding(.bottom, 4)
            }
        }
    }
}


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

#Preview {
    NotificationsView()
        .modelContainer(for: [Exam.self, DailyNote.self], inMemory: true)
}
