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
 
    // MARK: Dependencies
    private var modelContext: ModelContext
 
    // MARK: State – lista
    var exams: [Exam] = []
    var selectedFilter: ExamFilter = .upcoming
 
    // MARK: State – sheet
    var showingAddExam = false
 
    // MARK: State – AddExamSheet mezők
    var draftSubject  = ""
    var draftDate     = Date()
    var draftPriority: Exam.Priority = .medium
    var draftNotes    = ""
 
    // MARK: Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchExams()
    }
 
    // MARK: - Fetch
 
    func fetchExams() {
        let descriptor = FetchDescriptor<Exam>(
            sortBy: [SortDescriptor(\.date)]
        )
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
        case .upcoming:
            return exams.filter { !$0.isCompleted && $0.daysUntil >= 0 }
        case .completed:
            return exams.filter { $0.isCompleted }
        case .all:
            return exams
        }
    }
 
    var isEmpty: Bool { filteredExams.isEmpty }
 
    // MARK: - Sheet
 
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
 
    // MARK: - CRUD
 
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
 
    // MARK: - Urgency color (ExamDetailRow-hoz)
 
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
    }
}
