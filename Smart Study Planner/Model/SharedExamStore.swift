import Foundation

struct ExamSnapshot: Codable {
    let subject: String
    let date: Date
    let daysUntil: Int
    let priorityRaw: String
    let isCompleted: Bool
    let urgencyLevel: String
}

final class SharedExamStore {
    static let suiteName = "group.com.kevin.smartstudyplanner"
    static let key = "widget_exams"

    static func save(_ snapshots: [ExamSnapshot]) {  
        if let data = try? JSONEncoder().encode(snapshots) {
            UserDefaults(suiteName: suiteName)?.set(data, forKey: key)
        }
    }

    static func load() -> [ExamSnapshot] {
        guard
            let data = UserDefaults(suiteName: suiteName)?.data(forKey: key),
            let snapshots = try? JSONDecoder().decode([ExamSnapshot].self, from: data)
        else { return [] }
        return snapshots
    }
}
