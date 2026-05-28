
import SwiftData
import Foundation

@Model
final class DailyNote {
var id: UUID
var date: Date
var subject: String
var content: String
var studyGoals: [String]
var isDone: Bool
var linkedExamID: UUID?

     init(date: Date = .now, subject: String, content: String,
          studyGoals: [String] = [], linkedExamID: UUID? = nil) {
         self.id = UUID()
         self.date = date
         self.subject = subject
         self.content = content
         self.studyGoals = studyGoals
         self.isDone = false
         self.linkedExamID = linkedExamID
     }
 }
