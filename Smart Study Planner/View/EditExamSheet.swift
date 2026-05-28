import SwiftUI
import SwiftData

struct EditexamSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
            if horizontalSizeClass == .regular {
                
                ScrollView {
                    VStack(spacing: 20) {
                        HStack(alignment: .top, spacing: 20) {
                            
                            VStack(spacing: 16) {
                                iPadSection(title: "Tantárgy adatai") {
                                    VStack(spacing: 12) {
                                        TextField("Tantárgy neve", text: $subject)
                                            .textFieldStyle(.roundedBorder)
                                        DatePicker("Időpontja", selection: $date, displayedComponents: .date)
                                            .environment(\.locale, Locale(identifier: "hu_HU"))
                                    }
                                }

                                iPadSection(title: "Prioritás") {
                                    Picker("Prioritás", selection: $priority) {
                                        ForEach(Exam.Priority.allCases, id: \.self) { p in
                                            Label(p.rawValue, systemImage: p.icon).tag(p)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            .frame(maxWidth: .infinity)

                            
                            VStack(spacing: 16) {
                                iPadSection(title: "Megjegyzés (opcionális)") {
                                    TextEditor(text: $notes)
                                        .frame(minHeight: 150)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }

                                iPadSection(title: "Állapot") {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Toggle("Teljesítve", isOn: Binding(
                                            get: { exam.isCompleted },
                                            set: { _ in }
                                        ))
                                        .disabled(true)
                                        .foregroundStyle(.secondary)
                                        Text("A teljesítés állapotát a listán swipe-pal változtathatod.")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(32)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                
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
                            set: { _ in }
                        ))
                        .disabled(true)
                        .foregroundStyle(.secondary)
                        Text("A teljesítés állapotát a listán swipe-pal változtathatod.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
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


private struct iPadSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        }
    }
}
