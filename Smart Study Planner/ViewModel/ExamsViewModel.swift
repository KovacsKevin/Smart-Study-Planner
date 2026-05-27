//
//  ExamsViewModel.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class ExamsViewModel {

    // MARK: - Dependencies
    private var modelContext: ModelContext

    // MARK: - State – lista
    var exams: [Exam] = []
    var selectedFilter: ExamFilter = .upcoming

    // MARK: - State – sheetek
    var showingAddExam  = false
    var examToEdit: Exam? = nil   // nil = zárva, non-nil = EditExamSheet nyitva

    // MARK: - State – AddExamSheet mezők
    var draftSubject  = ""
    var draftDate     = Date()
    var draftPriority: Exam.Priority = .medium
    var draftNotes    = ""

    // MARK: - Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchExams()
    }

    // MARK: - Fetch

    func fetchExams() {
        let descriptor = FetchDescriptor<Exam>(sortBy: [SortDescriptor(\.date)])
        exams = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Filter

    enum ExamFilter: String, CaseIterable {
        case upcoming  = "Közelgő"
        case completed = "Teljesített"
        case all       = "Mind"
    }

    var filteredExams: [Exam] {
        switch selectedFilter {
        case .upcoming:  return exams.filter { !$0.isCompleted && $0.daysUntil >= 0 }
        case .completed: return exams.filter { $0.isCompleted }
        case .all:       return exams
        }
    }

    var isEmpty: Bool { filteredExams.isEmpty }

    // MARK: - Add sheet

    func openAddExamSheet() {
        resetDraft()
        showingAddExam = true
    }

    func dismissAddExamSheet() {
        showingAddExam = false
        resetDraft()
    }

    private func resetDraft() {
        draftSubject  = ""
        draftDate     = Date()
        draftPriority = .medium
        draftNotes    = ""
    }

    var canSaveDraft: Bool {
        !draftSubject.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func saveDraftExam() {
        guard canSaveDraft else { return }
        let exam = Exam(
            subject: draftSubject.trimmingCharacters(in: .whitespaces),
            date: draftDate,
            priority: draftPriority,
            notes: draftNotes
        )
        modelContext.insert(exam)
        save()
        fetchExams()
        dismissAddExamSheet()
    }

    // MARK: - Edit sheet

    func openEditSheet(for exam: Exam) {
        examToEdit = exam
    }

    func saveEdited(exam: Exam, subject: String, date: Date, priority: Exam.Priority, notes: String) {
        exam.subject  = subject
        exam.date     = date
        exam.priority = priority
        exam.notes    = notes
        save()
        fetchExams()
        examToEdit = nil
    }

    // MARK: - CRUD

    func toggleCompleted(_ exam: Exam) {
        exam.isCompleted.toggle()
        save()
        fetchExams()
    }

    func deleteExam(_ exam: Exam) {
        modelContext.delete(exam)
        save()
        fetchExams()
    }

    func deleteExams(at offsets: IndexSet) {
        offsets.map { filteredExams[$0] }.forEach { modelContext.delete($0) }
        save()
        fetchExams()
    }

    // MARK: - Urgency color

    func urgencyColor(for exam: Exam) -> Color {
        if exam.isCompleted { return .green }
        switch exam.daysUntil {
        case ..<1:  return .red
        case 1...3: return .orange
        default:    return .indigo
        }
    }

    // MARK: - Persistence

    private func save() {
        try? modelContext.save()
        
        let snapshots = exams
            .filter { !$0.isCompleted && $0.daysUntil >= 0 }
            .sorted { $0.date < $1.date }
            .prefix(5)
            .map {
                ExamSnapshot(
                    subject: $0.subject,
                    date: $0.date,
                    daysUntil: $0.daysUntil,
                    priorityRaw: $0.priority.rawValue,
                    isCompleted: $0.isCompleted,
                    urgencyLevel: $0.urgencyLevel
                )
            }
        SharedExamStore.save(Array(snapshots))
    }
}
