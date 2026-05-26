//
//  EditExamSheet.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//

import SwiftUI
import SwiftData

struct EditexamSheet: View {
    @Environment(\.dismiss) private var dismiss

    let exam: Exam
    let onSave: (String, Date, Exam.Priority, String) -> Void

    @State private var subject: String
    @State private var date: Date
    @State private var priority: Exam.Priority
    @State private var notes: String

    init(exam: Exam, onSave: @escaping (String, Date, Exam.Priority, String) -> Void) {
        self.exam = exam
        self.onSave = onSave
        _subject  = State(initialValue: exam.subject)
        _date     = State(initialValue: exam.date)
        _priority = State(initialValue: exam.priority)
        _notes    = State(initialValue: exam.notes)
    }

    private var canSave: Bool {
        !subject.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Tantárgy adatai") {
                    TextField("Tantárgy neve", text: $subject)
                    DatePicker("Időpontja", selection: $date, displayedComponents: .date)
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

                Section {
                    Toggle("Teljesítve", isOn: Binding(
                        get: { exam.isCompleted },
                        set: { _ in }   // toggleCompleted az ExamsViewModel-en keresztül kezelendő
                    ))
                    .disabled(true)
                    .foregroundStyle(.secondary)

                    Text("A teljesítés állapotát a listán swipe-pal változtathatod.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .navigationTitle("Vizsga szerkesztése")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Mégse") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mentés") {
                        onSave(
                            subject.trimmingCharacters(in: .whitespaces),
                            date,
                            priority,
                            notes
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}

