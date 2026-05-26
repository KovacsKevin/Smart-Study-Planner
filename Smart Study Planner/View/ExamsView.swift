//
//  ExamsView.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//

import SwiftUI
import SwiftData

struct ExamsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exam.date) private var exams: [Exam]
    @State private var showingAddExam = false
    @State private var selectedFilter: ExamFilter = .upcoming
    
    enum ExamFilter: String, CaseIterable {
        case upcoming = "Közelgő"
        case completed = "Teljesített"
        case all = "Mind"
    }
    
    private var filteredExams: [Exam] {
        switch selectedFilter {
        case .upcoming: return exams.filter { !$0.isCompleted && $0.daysUntil >= 0 }
        case .completed: return exams.filter { $0.isCompleted }
        case .all: return exams
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter picker
                Picker("Szűrő", selection: $selectedFilter) {
                    ForEach(ExamFilter.allCases, id: \.self) {
                        Text($0.rawValue).tag($0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemGroupedBackground))
                
                if filteredExams.isEmpty {
                    ExamsEmptyState(filter: selectedFilter)
                } else {
                    List {
                        ForEach(filteredExams) { exam in
                            ExamDetailRow(exam: exam)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        modelContext.delete(exam)
                                    } label: {
                                        Label("Törlés", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        exam.isCompleted.toggle()
                                    } label: {
                                        Label(
                                            exam.isCompleted ? "Visszaállítás" : "Kész",
                                            systemImage: exam.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                        )
                                    }
                                    .tint(.green)
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Vizsgák & ZH-k")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddExam = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showingAddExam) {
                AddExamSheet()
            }
        }
    }
}

// MARK: - Exam Detail Row
struct ExamDetailRow: View {
    let exam: Exam
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "hu_HU")
        formatter.dateStyle = .long
        return formatter.string(from: exam.date)
    }
    
    private var urgencyColor: Color {
        if exam.isCompleted { return .green }
        switch exam.daysUntil {
        case ..<1: return .red
        case 1...3: return .orange
        default: return .indigo
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Priority indicator
            VStack {
                Image(systemName: exam.isCompleted ? "checkmark.circle.fill" : exam.priority.icon)
                    .font(.title3)
                    .foregroundStyle(urgencyColor)
            }
            .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(exam.subject)
                        .font(.body)
                        .fontWeight(.semibold)
                        .strikethrough(exam.isCompleted)
                        .foregroundStyle(exam.isCompleted ? .secondary : .primary)
                    Spacer()
                    Text(exam.urgencyLevel)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(urgencyColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(urgencyColor.opacity(0.12))
                        .clipShape(Capsule())
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text(dateString)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
                
                if !exam.notes.isEmpty {
                    Text(exam.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Exam Sheet
struct AddExamSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var subject = ""
    @State private var date = Date()
    @State private var priority: Exam.Priority = .medium
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tantárgy adatai") {
                    TextField("Tantárgy neve (pl. Matematika)", text: $subject)
                    DatePicker("Időpontja", selection: $date, in: Date()..., displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "hu_HU"))
                }
                
                Section("Prioritás") {
                    Picker("Prioritás", selection: $priority) {
                        ForEach(Exam.Priority.allCases, id: \.self) { p in
                            Label(p.rawValue, systemImage: p.icon).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Megjegyzés (opcionális)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Új vizsga / ZH")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Mégse") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Hozzáadás") {
                        let exam = Exam(subject: subject, date: date, priority: priority, notes: notes)
                        modelContext.insert(exam)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(subject.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Empty State
struct ExamsEmptyState: View {
    let filter: ExamsView.ExamFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: filter == .completed ? "checkmark.seal.fill" : "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.indigo.opacity(0.4))
            Text(filter == .completed ? "Még nincs teljesített vizsga" : "Nincsenek közelgő vizsgák")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(filter == .completed ? "A teljesített vizsgáid itt jelennek meg." : "Add hozzá az első vizsgádat a + gombbal!")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Preview
#Preview {
    ExamsView()
        .modelContainer(for: [Exam.self, DailyNote.self], inMemory: true)
}
