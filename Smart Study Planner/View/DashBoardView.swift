import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Exam.date) private var exams: [Exam]
    @Query(sort: \DailyNote.date, order: .reverse) private var notes: [DailyNote]
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var upcomingExams: [Exam] {
        exams.filter { $0.daysUntil >= 0 && !$0.isCompleted }.prefix(3).map { $0 }
    }
    
    private var todayNote: DailyNote? {
        notes.first { Calendar.current.isDateInToday($0.date) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if horizontalSizeClass == .regular {
                    
                    VStack(alignment: .leading, spacing: 28) {
                        HeroHeaderView()
                        
                        QuickStatsRow(exams: exams)
                            .frame(maxWidth: 700)
                        
                        HStack(alignment: .top, spacing: 20) {
                            
                            VStack(alignment: .leading, spacing: 20) {
                                VStack(alignment: .leading, spacing: 12) {
                                    SectionHeader(title: "Mai tanulási napló", icon: "note.text")
                                    if let note = todayNote {
                                        TodayNoteCard(note: note)
                                    } else {
                                        EmptyNoteCard()
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            
                            
                            VStack(alignment: .leading, spacing: 12) {
                                SectionHeader(title: "Közelgő vizsgák", icon: "calendar.badge.exclamationmark")
                                if upcomingExams.isEmpty {
                                    EmptyExamsCard()
                                } else {
                                    ForEach(upcomingExams) { exam in
                                        ExamRowCard(exam: exam)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                } else {
                    
                    VStack(alignment: .leading, spacing: 24) {
                        HeroHeaderView()
                        QuickStatsRow(exams: exams)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Mai tanulási napló", icon: "note.text")
                            if let note = todayNote {
                                TodayNoteCard(note: note)
                            } else {
                                EmptyNoteCard()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Közelgő vizsgák", icon: "calendar.badge.exclamationmark")
                            if upcomingExams.isEmpty {
                                EmptyExamsCard()
                            } else {
                                ForEach(upcomingExams) { exam in
                                    ExamRowCard(exam: exam)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Smart Study Planner")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HeroHeaderView: View {
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Jó reggelt! ☀️"
        case 12..<17: return "Jó napot! 🌤"
        case 17..<21: return "Jó estét! 🌙"
        default: return "Jó éjszakát! 🌟"
        }
    }
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateFormat = "yyyy. MMMM d., EEEE"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(greeting)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            Text(dateString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 8)
    }
}

struct QuickStatsRow: View {
    let exams: [Exam]
    
    private var upcoming: Int { exams.filter { $0.daysUntil >= 0 && !$0.isCompleted }.count }
    private var thisWeek: Int { exams.filter { $0.daysUntil >= 0 && $0.daysUntil <= 7 && !$0.isCompleted }.count }
    private var completed: Int { exams.filter { $0.isCompleted }.count }
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(upcoming)", label: "Közelgő", color: .indigo, icon: "calendar")
            StatCard(value: "\(thisWeek)", label: "Ez a hét", color: .orange, icon: "clock")
            StatCard(value: "\(completed)", label: "Teljesített", color: .green, icon: "checkmark.seal")
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.indigo)
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}

struct TodayNoteCard: View {
    let note: DailyNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(note.subject)
                .font(.headline)
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            if !note.studyGoals.isEmpty {
                Divider()
                ForEach(note.studyGoals, id: \.self) { goal in
                    Label(goal, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

struct EmptyNoteCard: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Még nincs mai napló")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Készíts tanulási tervet a mai napra!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "square.and.pencil")
                .font(.title2)
                .foregroundStyle(.indigo)
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

struct ExamRowCard: View {
    let exam: Exam
    
    var urgencyColor: Color {
        switch exam.daysUntil {
        case ..<1: return .red
        case 1...3: return .orange
        default: return .indigo
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6)
                .fill(urgencyColor)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exam.subject)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(exam.urgencyLevel)
                    .font(.caption)
                    .foregroundStyle(urgencyColor)
            }
            
            Spacer()
            
            Image(systemName: exam.priority.icon)
                .foregroundStyle(urgencyColor)
                .font(.title3)
        }
        .padding(14)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

struct EmptyExamsCard: View {
    var body: some View {
        HStack {
            Image(systemName: "party.popper.fill")
                .font(.title2)
                .foregroundStyle(.green)
            Text("Nincs közelgő vizsga – jó pihenést! 🎉")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Exam.self, DailyNote.self], inMemory: true)
}
