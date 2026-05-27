//
//  ExamsView.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//

import SwiftUI
import SwiftData

struct ExamsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exam.date) private var exams: [Exam]
    @State private var vm: ExamsViewModel?

    var body: some View {
        NavigationStack {
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
                // FIX: unwrap vm here so AddExamSheet receives a concrete ExamsViewModel
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
}

// MARK: - Exam Detail Row
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

// MARK: - Add Exam Sheet
struct AddExamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ExamsViewModel

    var body: some View {
        NavigationStack {
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
}

// MARK: - Edit Exam Sheet
struct EditExamSheet: View {
    @Environment(\.dismiss) private var dismiss

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
