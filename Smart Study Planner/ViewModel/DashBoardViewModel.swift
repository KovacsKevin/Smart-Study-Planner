
import SwiftUI
import SwiftData

@MainActor
@Observable
final class DashboardViewModel {
 
    
    private var modelContext: ModelContext
 
    
    var exams: [Exam] = []
    var notes: [DailyNote] = []
 
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchAll()
    }
 
    
 
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
 
    
 
    var upcomingCount: Int {
        exams.filter { $0.daysUntil >= 0 && !$0.isCompleted }.count
    }
 
    var thisWeekCount: Int {
        exams.filter { $0.daysUntil >= 0 && $0.daysUntil <= 7 && !$0.isCompleted }.count
    }
 
    var completedCount: Int {
        exams.filter(\.isCompleted).count
    }
 
    
 
    var upcomingExams: [Exam] {
        exams
            .filter { $0.daysUntil >= 0 && !$0.isCompleted }
            .prefix(3)
            .map { $0 }
    }
 
    
 
    var todayNote: DailyNote? {
        notes.first { Calendar.current.isDateInToday($0.date) }
    }
 
    var hasTodayNote: Bool { todayNote != nil }
 
    
 
    func urgencyColor(for exam: Exam) -> Color {
        switch exam.daysUntil {
        case ..<1:  return .red
        case 1...3: return .orange
        default:    return .indigo
        }
    }
}
