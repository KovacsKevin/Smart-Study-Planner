


import SwiftData
import Foundation

@Model
class Exam {
    var id: UUID
    var subject: String
    var date: Date
    var priority: Priority
    var isCompleted: Bool
    var notes: String
    
    init(subject: String, date: Date, priority: Priority = .medium, notes: String = "") {
        self.id = UUID()
        self.subject = subject
        self.date = date
        self.priority = priority
        self.isCompleted = false
        self.notes = notes
    }
    
    enum Priority: String, Codable, CaseIterable {
        case low = "Alacsony"
        case medium = "Közepes"
        case high = "Magas"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            }
        }
        
        var icon: String {
            switch self {
            case .low: return "arrow.down.circle.fill"
            case .medium: return "minus.circle.fill"
            case .high: return "exclamationmark.circle.fill"
            }
        }
    }
    
    var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let examDay = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: today, to: examDay).day ?? 0
    }
    
    var urgencyLevel: String {
        switch daysUntil {
        case ..<0: return "Lejárt"
        case 0: return "Ma van!"
        case 1...3: return "Sürgős"
        case 4...7: return "Ezen a héten"
        default: return "\(daysUntil) nap múlva"
        }
    }
}
