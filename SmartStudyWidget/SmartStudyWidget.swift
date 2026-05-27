import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct ExamEntry: TimelineEntry {
    let date: Date
    let exams: [ExamSnapshot]
}

// MARK: - Provider
struct ExamWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExamEntry {
        ExamEntry(date: .now, exams: [
            ExamSnapshot(
                subject: "Matematika",
                date: .now.addingTimeInterval(86400 * 3),
                daysUntil: 3,
                priorityRaw: "Magas",
                isCompleted: false,
                urgencyLevel: "Sürgős"
            )
        ])
    }

    func getSnapshot(in context: Context, completion: @escaping (ExamEntry) -> Void) {
        completion(ExamEntry(date: .now, exams: SharedExamStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExamEntry>) -> Void) {
        let entry = ExamEntry(date: .now, exams: SharedExamStore.load())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

// MARK: - Urgency Color
func urgencyColor(daysUntil: Int) -> Color {
    switch daysUntil {
    case ..<1:  return .red
    case 1...3: return .orange
    default:    return .indigo
    }
}

// MARK: - Small Widget (2x2)
struct SmallWidgetView: View {
    let entry: ExamEntry

    var body: some View {
        if let next = entry.exams.first {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "graduationcap.fill")
                        .foregroundStyle(.indigo)
                        .font(.caption)
                    Text("Következő vizsga")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(next.subject)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(2)
                Text(next.urgencyLevel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(urgencyColor(daysUntil: next.daysUntil))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(urgencyColor(daysUntil: next.daysUntil).opacity(0.15))
                    .clipShape(Capsule())
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .containerBackground(.background, for: .widget)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("Nincs közelgő vizsga")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .containerBackground(.background, for: .widget)
        }
    }
}

// MARK: - Medium Widget (4x2)
struct MediumWidgetView: View {
    let entry: ExamEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(.indigo)
                Text("Közelgő vizsgák")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("\(entry.exams.count) db")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if entry.exams.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("Nincs közelgő vizsga 🎉")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.exams.prefix(3), id: \.subject) { exam in
                    HStack {
                        Circle()
                            .fill(urgencyColor(daysUntil: exam.daysUntil))
                            .frame(width: 8, height: 8)
                        Text(exam.subject)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Spacer()
                        Text(exam.urgencyLevel)
                            .font(.caption)
                            .foregroundStyle(urgencyColor(daysUntil: exam.daysUntil))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(.background, for: .widget)
    }
}

// MARK: - Widget
struct SmartStudyWidget: Widget {
    let kind = "SmartStudyWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ExamWidgetProvider()) { entry in
            ViewThatFits {
                SmallWidgetView(entry: entry)
                MediumWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Vizsgák")
        .description("Következő vizsgáid egy pillantásra.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
