
import WidgetKit
import SwiftUI
import SwiftData

@MainActor
@Observable
final class ExamsViewModel {

    
    private var modelContext: ModelContext

    
    var exams: [Exam] = []
    var selectedFilter: ExamFilter = .upcoming

    
    var showingAddExam  = false
    var examToEdit: Exam? = nil

    
    var draftSubject  = ""
    var draftDate     = Date()
    var draftPriority: Exam.Priority = .medium
    var draftNotes    = ""

    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchExams()
    }

   

    func fetchExams() {
        let descriptor = FetchDescriptor<Exam>(sortBy: [SortDescriptor(\.date)])
        exams = (try? modelContext.fetch(descriptor)) ?? []
    }

    

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

    

    func openEditSheet(for exam: Exam) {
        examToEdit = exam
    }

    

    func deleteExam(_ exam: Exam) {
        modelContext.delete(exam)
        fetchExams()
        save()
    }

    func toggleCompleted(_ exam: Exam) {
        exam.isCompleted.toggle()
        fetchExams()
        save()
    }

    func saveEdited(exam: Exam, subject: String, date: Date, priority: Exam.Priority, notes: String) {
        exam.subject  = subject
        exam.date     = date
        exam.priority = priority
        exam.notes    = notes
        fetchExams()
        save()
        examToEdit = nil
    }

    func deleteExams(at offsets: IndexSet) {
        offsets.map { filteredExams[$0] }.forEach { modelContext.delete($0) }
        fetchExams()
        save()
        
    }

    

    func urgencyColor(for exam: Exam) -> Color {
        if exam.isCompleted { return .green }
        switch exam.daysUntil {
        case ..<1:  return .red
        case 1...3: return .orange
        default:    return .indigo
        }
    }

    

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
        WidgetCenter.shared.reloadAllTimelines()
    }
}
