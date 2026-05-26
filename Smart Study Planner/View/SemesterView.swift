//
//  SemesterView.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//

import SwiftUI
import SwiftData

struct SemesterView: View {
    @Query private var exams: [Exam]
    @State private var viewModel = SemesterViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    SemesterProgressCard(
                        completed: viewModel.completedExams,
                        total: viewModel.totalExams,
                        progress: viewModel.progress
                    )
                    .padding(.horizontal, 20)

                    PriorityBreakdownCard(
                        highCount: viewModel.highPriorityCount,
                        mediumCount: viewModel.mediumPriorityCount,
                        lowCount: viewModel.lowPriorityCount
                    )
                    .padding(.horizontal, 20)

                    if !viewModel.examsByMonth.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Vizsganaptár")
                                .font(.headline)
                                .padding(.horizontal, 20)

                            ForEach(viewModel.examsByMonth, id: \.month) { item in
                                MonthSection(month: item.month, exams: item.exams)
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Félév előnézete")
            .navigationBarTitleDisplayMode(.large)
            // Sync @Query results into the ViewModel whenever they change
            .onChange(of: exams, initial: true) { _, newValue in
                viewModel.exams = newValue
            }
        }
    }
}

// MARK: - Semester Progress Card
struct SemesterProgressCard: View {
    let completed: Int
    let total: Int
    let progress: Double

    var progressLabel: String {
        if total == 0 { return "Még nincsenek vizsgák" }
        return "\(completed)/\(total) teljesítve"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Félév haladás")
                        .font(.headline)
                    Text(progressLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(.indigo, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .frame(width: 56, height: 56)
                .animation(.spring(duration: 0.8), value: progress)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 10)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress, height: 10)
                        .animation(.spring(duration: 0.8), value: progress)
                }
            }
            .frame(height: 10)
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

// MARK: - Priority Breakdown Card
struct PriorityBreakdownCard: View {
    let highCount: Int
    let mediumCount: Int
    let lowCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Prioritás megoszlás")
                .font(.headline)

            HStack(spacing: 12) {
                PriorityBar(label: "Magas",    count: highCount,   color: .red,    icon: "exclamationmark.circle.fill")
                PriorityBar(label: "Közepes",  count: mediumCount, color: .orange, icon: "minus.circle.fill")
                PriorityBar(label: "Alacsony", count: lowCount,    color: .green,  icon: "arrow.down.circle.fill")
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }
}

struct PriorityBar: View {
    let label: String
    let count: Int
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Month Section
struct MonthSection: View {
    let month: String
    let exams: [Exam]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(month.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                ForEach(Array(exams.enumerated()), id: \.element.id) { idx, exam in
                    TimelineExamRow(exam: exam, isLast: idx == exams.count - 1)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct TimelineExamRow: View {
    let exam: Exam
    let isLast: Bool

    // The ViewModel helpers are stateless pure functions,
    // so it's fine to call them directly here as well.
    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateFormat = "MMM d."
        return f.string(from: exam.date)
    }

    private var dotColor: Color {
        if exam.isCompleted { return .green }
        switch exam.priority {
        case .high:   return .red
        case .medium: return .orange
        case .low:    return .indigo
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 12, height: 12)
                    .padding(.top, 14)
                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 12)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(exam.subject)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .strikethrough(exam.isCompleted)
                        .foregroundStyle(exam.isCompleted ? .secondary : .primary)
                    Text(dateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if exam.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            .padding(.vertical, 12)
            .padding(.trailing, 4)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 2)
    }
}

// MARK: - Preview
#Preview {
    SemesterView()
        .modelContainer(for: [Exam.self, DailyNote.self], inMemory: true)
}
