import SwiftUI
import SwiftData

struct ExamsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \Exam.date) private var exams: [Exam]
    @State private var vm: ExamsViewModel?

    var body: some View {
        NavigationStack {
            if horizontalSizeClass == .regular {
                
                HStack(spacing: 0) {
                    
                    VStack(spacing: 0) {
                        Picker("Szűrő", selection: Binding(
                            get: { vm?.selectedFilter ?? .upcoming },
                            set: { vm?.selectedFilter = $0 }
                        )) {
                            ForEach(ExamsViewModel.ExamFilter.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemGroupedBackground))

                        if vm?.isEmpty ?? true {
                            ExamsEmptyState(filter: vm?.selectedFilter ?? .upcoming)
                        } else {
                            List {
                                ForEach(vm?.filteredExams ?? []) { exam in
                                    ExamDetailRow(
                                        exam: exam,
                                        urgencyColor: vm?.urgencyColor(for: exam) ?? .secondary
                                    )
                                    .swipeActions(edge: .leading) {
                                        Button {
                                            vm?.toggleCompleted(exam)
                                        } label: {
                                            Label(
                                                exam.isCompleted ? "Visszaállítás" : "Kész",
                                                systemImage: exam.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                            )
                                        }
                                        .tint(.green)
                                    }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            vm?.deleteExam(exam)
                                        } label: {
                                            Label("Törlés", systemImage: "trash")
                                        }
                                        Button {
                                            vm?.openEditSheet(for: exam)
                                        } label: {
                                            Label("Szerkesztés", systemImage: "pencil")
                                        }
                                        .tint(.indigo)
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Divider()

                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Összesítő")
                                .font(.headline)
                                .padding(.top, 16)

                            iPadStatPanel(
                                icon: "calendar",
                                color: .indigo,
                                title: "Közelgő vizsgák",
                                value: "\(exams.filter { !$0.isCompleted && $0.daysUntil >= 0 }.count) db"
                            )

                            iPadStatPanel(
                                icon: "exclamationmark.circle.fill",
                                color: .red,
                                title: "Magas prioritású",
                                value: "\(exams.filter { !$0.isCompleted && $0.priority == .high }.count) db"
                            )

                            iPadStatPanel(
                                icon: "checkmark.seal.fill",
                                color: .green,
                                title: "Teljesített",
                                value: "\(exams.filter { $0.isCompleted }.count) db"
                            )

                            iPadStatPanel(
                                icon: "clock.fill",
                                color: .orange,
                                title: "Ezen a héten",
                                value: "\(exams.filter { !$0.isCompleted && $0.daysUntil >= 0 && $0.daysUntil <= 7 }.count) db"
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                    .frame(width: 260)
                    .background(Color(.secondarySystemGroupedBackground))
                }
                .background(Color(.systemGroupedBackground))

            } else {
                
                VStack(spacing: 0) {
                    Picker("Szűrő", selection: Binding(
                        get: { vm?.selectedFilter ?? .upcoming },
                        set: { vm?.selectedFilter = $0 }
                    )) {
                        ForEach(ExamsViewModel.ExamFilter.allCases, id: \.self) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))

                    if vm?.isEmpty ?? true {
                        ExamsEmptyState(filter: vm?.selectedFilter ?? .upcoming)
                    } else {
                        List {
                            ForEach(vm?.filteredExams ?? []) { exam in
                                ExamDetailRow(
                                    exam: exam,
                                    urgencyColor: vm?.urgencyColor(for: exam) ?? .secondary
                                )
                                .swipeActions(edge: .leading) {
                                    Button {
                                        vm?.toggleCompleted(exam)
                                    } label: {
                                        Label(
                                            exam.isCompleted ? "Visszaállítás" : "Kész",
                                            systemImage: exam.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(.green)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        vm?.deleteExam(exam)
                                    } label: {
                                        Label("Törlés", systemImage: "trash")
                                    }
                                    Button {
                                        vm?.openEditSheet(for: exam)
                                    } label: {
                                        Label("Szerkesztés", systemImage: "pencil")
                                    }
                                    .tint(.indigo)
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationTitle("Vizsgák & ZH-k")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    vm?.openAddExamSheet()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { vm?.showingAddExam ?? false },
            set: { if !$0 { vm?.dismissAddExamSheet() } }
        )) {
            if let vm {
                AddExamSheet(viewModel: vm)
            }
        }
        .sheet(item: Binding(
            get: { vm?.examToEdit },
            set: { vm?.examToEdit = $0 }
        )) { exam in
            EditExamSheet(exam: exam) { subject, date, priority, notes in
                vm?.saveEdited(exam: exam, subject: subject, date: date, priority: priority, notes: notes)
            }
        }
        .onChange(of: exams, initial: true) { _, newValue in
            if vm == nil {
                vm = ExamsViewModel(modelContext: modelContext)
            }
            vm?.exams = newValue
        }
    }
}


private struct iPadStatPanel: View {
    let icon: String
    let color: Color
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}


struct ExamDetailRow: View {
    let exam: Exam
    let urgencyColor: Color

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateStyle = .long
        return formatter.string(from: exam.date)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: exam.isCompleted ? "checkmark.circle.fill" : exam.priority.icon)
                .font(.title3)
                .foregroundStyle(urgencyColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exam.subject)
                        .font(.body)
                        .fontWeight(.semibold)
                        .strikethrough(exam.isCompleted)
                        .foregroundStyle(exam.isCompleted ? .secondary : .primary)
                    Spacer()
                    Text(exam.urgencyLevel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(urgencyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(urgencyColor.opacity(0.12))
                        .clipShape(Capsule())
                }

                HStack(spacing: 4) {
                    Image(systemName: "calendar").font(.caption2)
                    Text(dateString).font(.caption)
                }
                .foregroundStyle(.secondary)

                if !exam.notes.isEmpty {
                    Text(exam.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}


struct AddExamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Bindable var viewModel: ExamsViewModel

    var body: some View {
        NavigationStack {
            if horizontalSizeClass == .regular {
                ScrollView {
                    VStack(spacing: 20) {
                        HStack(alignment: .top, spacing: 20) {
                            VStack(spacing: 16) {
                                iPadFormSection(title: "Tantárgy adatai") {
                                    VStack(spacing: 12) {
                                        TextField("Tantárgy neve (pl. Matematika)", text: $viewModel.draftSubject)
                                            .textFieldStyle(.roundedBorder)
                                        DatePicker("Időpontja", selection: $viewModel.draftDate, in: Date()..., displayedComponents: .date)
                                            .environment(\.locale, Locale(identifier: "hu_HU"))
                                    }
                                }
                                iPadFormSection(title: "Prioritás") {
                                    Picker("Prioritás", selection: $viewModel.draftPriority) {
                                        ForEach(Exam.Priority.allCases, id: \.self) { p in
                                            Label(p.rawValue, systemImage: p.icon).tag(p)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            .frame(maxWidth: .infinity)

                            iPadFormSection(title: "Megjegyzés (opcionális)") {
                                TextEditor(text: $viewModel.draftNotes)
                                    .frame(minHeight: 150)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(32)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                Form {
                    Section("Tantárgy adatai") {
                        TextField("Tantárgy neve (pl. Matematika)", text: $viewModel.draftSubject)
                        DatePicker("Időpontja", selection: $viewModel.draftDate, in: Date()..., displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "hu_HU"))
                    }
                    Section("Prioritás") {
                        Picker("Prioritás", selection: $viewModel.draftPriority) {
                            ForEach(Exam.Priority.allCases, id: \.self) { p in
                                Label(p.rawValue, systemImage: p.icon).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Megjegyzés (opcionális)") {
                        TextEditor(text: $viewModel.draftNotes)
                            .frame(minHeight: 80)
                    }
                }
            }
        }
        .navigationTitle("Új vizsga / ZH")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Mégse") { viewModel.dismissAddExamSheet() }
                    .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Hozzáadás") { viewModel.saveDraftExam() }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canSaveDraft)
            }
        }
    }
}


struct EditExamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let exam: Exam
    let onSave: (String, Date, Exam.Priority, String) -> Void

    @State private var subject: String
    @State private var date: Date
    @State private var priority: Exam.Priority
    @State private var notes: String

    init(exam: Exam, onSave: @escaping (String, Date, Exam.Priority, String) -> Void) {
        self.exam = exam
        self.onSave = onSave
        _subject  = State(initialValue: exam.subject)
        _date     = State(initialValue: exam.date)
        _priority = State(initialValue: exam.priority)
        _notes    = State(initialValue: exam.notes)
    }

    private var canSave: Bool {
        !subject.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            if horizontalSizeClass == .regular {
                ScrollView {
                    VStack(spacing: 20) {
                        HStack(alignment: .top, spacing: 20) {
                            VStack(spacing: 16) {
                                iPadFormSection(title: "Tantárgy adatai") {
                                    VStack(spacing: 12) {
                                        TextField("Tantárgy neve", text: $subject)
                                            .textFieldStyle(.roundedBorder)
                                        DatePicker("Időpontja", selection: $date, displayedComponents: .date)
                                            .environment(\.locale, Locale(identifier: "hu_HU"))
                                    }
                                }
                                iPadFormSection(title: "Prioritás") {
                                    Picker("Prioritás", selection: $priority) {
                                        ForEach(Exam.Priority.allCases, id: \.self) { p in
                                            Label(p.rawValue, systemImage: p.icon).tag(p)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 16) {
                                iPadFormSection(title: "Megjegyzés (opcionális)") {
                                    TextEditor(text: $notes)
                                        .frame(minHeight: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                iPadFormSection(title: "Állapot") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Toggle("Teljesítve", isOn: Binding(
                                            get: { exam.isCompleted },
                                            set: { _ in }
                                        ))
                                        .disabled(true)
                                        .foregroundStyle(.secondary)
                                        Text("A teljesítés állapotát a listán swipe-pal változtathatod.")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(32)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                Form {
                    Section("Tantárgy adatai") {
                        TextField("Tantárgy neve", text: $subject)
                        DatePicker("Időpontja", selection: $date, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "hu_HU"))
                    }
                    Section("Prioritás") {
                        Picker("Prioritás", selection: $priority) {
                            ForEach(Exam.Priority.allCases, id: \.self) { p in
                                Label(p.rawValue, systemImage: p.icon).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section("Megjegyzés (opcionális)") {
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                    }
                }
            }
        }
        .navigationTitle("Vizsga szerkesztése")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Mégse") { dismiss() }
                    .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Mentés") {
                    onSave(subject.trimmingCharacters(in: .whitespaces), date, priority, notes)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(!canSave)
            }
        }
    }
}

// MARK: - Empty State
struct ExamsEmptyState: View {
    let filter: ExamsViewModel.ExamFilter

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: filter == .completed ? "checkmark.seal.fill" : "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.indigo.opacity(0.4))
            Text(filter == .completed ? "Még nincs teljesített vizsga" : "Nincsenek közelgő vizsgák")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(filter == .completed ? "A teljesített vizsgáid itt jelennek meg." : "Add hozzá az első vizsgádat a + gombbal!")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - iPad Form Section Helper
private struct iPadFormSection<Content: View>: View {
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
