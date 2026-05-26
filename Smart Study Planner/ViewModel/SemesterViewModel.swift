//
//  SemesterViewModel.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//


//
//  SemesterViewModel.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//

import SwiftUI
import SwiftData
import Combine

@MainActor
@Observable
final class SemesterViewModel {

    // MARK: - Input (set by the View after @Query delivers results)

    var exams: [Exam] = [] {
        didSet { recalculate() }
    }

    // MARK: - Derived state (read-only for the View)

    private(set) var totalExams: Int = 0
    private(set) var completedExams: Int = 0
    private(set) var progress: Double = 0

    private(set) var highPriorityCount: Int = 0
    private(set) var mediumPriorityCount: Int = 0
    private(set) var lowPriorityCount: Int = 0

    /// Exams grouped and sorted by month, e.g. [("2026. május", [Exam, …]), …]
    private(set) var examsByMonth: [(month: String, exams: [Exam])] = []

    // MARK: - Helpers

    var progressLabel: String {
        guard totalExams > 0 else { return "Még nincsenek vizsgák" }
        return "\(completedExams)/\(totalExams) teljesítve"
    }

    var progressPercent: Int { Int(progress * 100) }

    // MARK: - Private recalculation

    private func recalculate() {
        totalExams     = exams.count
        completedExams = exams.filter(\.isCompleted).count
        progress       = totalExams > 0 ? Double(completedExams) / Double(totalExams) : 0

        highPriorityCount   = pendingCount(for: .high)
        mediumPriorityCount = pendingCount(for: .medium)
        lowPriorityCount    = pendingCount(for: .low)

        examsByMonth = buildExamsByMonth()
    }

    private func pendingCount(for priority: Exam.Priority) -> Int {
        exams.filter { $0.priority == priority && !$0.isCompleted }.count
    }

    private func buildExamsByMonth() -> [(month: String, exams: [Exam])] {
        let formatter = monthFormatter()

        let grouped = Dictionary(grouping: exams) { exam in
            formatter.string(from: exam.date)
        }

        return grouped
            .sorted { a, b in
                let dateA = formatter.date(from: a.key) ?? .distantPast
                let dateB = formatter.date(from: b.key) ?? .distantPast
                return dateA < dateB
            }
            .map { key, value in
                (month: key, exams: value.sorted { $0.date < $1.date })
            }
    }

    // MARK: - Formatters (cached as local statics to avoid repeated allocation)

    private func monthFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateFormat = "MMMM yyyy"
        return f
    }

    // MARK: - Dot color helper (used by TimelineExamRow)

    func dotColor(for exam: Exam) -> Color {
        if exam.isCompleted { return .green }
        switch exam.priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .indigo
        }
    }

    // MARK: - Short date string helper (used by TimelineExamRow)

    func shortDateString(for exam: Exam) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateFormat = "MMM d."
        return f.string(from: exam.date)
    }
}