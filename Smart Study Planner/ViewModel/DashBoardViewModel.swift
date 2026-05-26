//
//  DashBoardViewModel.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//
import SwiftUI
import SwiftData

@MainActor
@Observable
final class DashboardViewModel {
 
    // MARK: Dependencies
    private var modelContext: ModelContext
 
    // MARK: State
    var exams: [Exam] = []
    var notes: [DailyNote] = []
 
    // MARK: Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAll()
    }
 
    // MARK: - Fetch
 
    func fetchAll() {
        fetchExams()
        fetchNotes()
    }
 
    private func fetchExams() {
        let descriptor = FetchDescriptor<Exam>(
            sortBy: [SortDescriptor(\.date)]
        )
        exams = (try? modelContext.fetch(descriptor)) ?? []
    }
 
    private func fetchNotes() {
        let descriptor = FetchDescriptor<DailyNote>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        notes = (try? modelContext.fetch(descriptor)) ?? []
    }
 
    // MARK: - Computed: Hero Header
 
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Jó reggelt! ☀️"
        case 12..<17: return "Jó napot! 🌤"
        case 17..<21: return "Jó estét! 🌙"
        default:      return "Jó éjszakát! 🌟"
        }
    }
 
    var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateFormat = "yyyy. MMMM d., EEEE"
        return f.string(from: .now)
    }
 
    // MARK: - Computed: Quick Stats
 
    var upcomingCount: Int {
        exams.filter { $0.daysUntil >= 0 && !$0.isCompleted }.count
    }
 
    var thisWeekCount: Int {
        exams.filter { $0.daysUntil >= 0 && $0.daysUntil <= 7 && !$0.isCompleted }.count
    }
 
    var completedCount: Int {
        exams.filter(\.isCompleted).count
    }
 
    // MARK: - Computed: Upcoming Exams (max 3)
 
    var upcomingExams: [Exam] {
        exams
            .filter { $0.daysUntil >= 0 && !$0.isCompleted }
            .prefix(3)
            .map { $0 }
    }
 
    // MARK: - Computed: Today's Note
 
    var todayNote: DailyNote? {
        notes.first { Calendar.current.isDateInToday($0.date) }
    }
 
    var hasTodayNote: Bool { todayNote != nil }
 
    // MARK: - Urgency color (ExamRowCard-hoz)
 
    func urgencyColor(for exam: Exam) -> Color {
        switch exam.daysUntil {
        case ..<1:  return .red
        case 1...3: return .orange
        default:    return .indigo
        }
    }
}
