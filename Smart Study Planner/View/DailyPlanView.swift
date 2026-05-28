import SwiftUI
import SwiftData

struct DailyPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DailyNote.date, order: .reverse) private var notes: [DailyNote]
    @State private var showingAddNote = false
    @State private var noteToEdit: DailyNote? = nil
    @State private var selectedDate = Date()
    
    private var noteForSelectedDate: DailyNote? {
        notes.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    DateScrollPicker(selectedDate: $selectedDate)
                    
                    if let note = noteForSelectedDate {
                        DailyNoteDetailView(
                            note: note,
                            onEdit: { noteToEdit = note },
                            onDelete: {
                                modelContext.delete(note)
                                try? modelContext.save()
                            }
                        )
                    } else {
                        EmptyDayView(date: selectedDate, onCreate: { showingAddNote = true })
                    }
                    
                    if !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Korábbi naplók")
                                .font(.headline)
                                .padding(.horizontal, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(notes.prefix(10)) { note in
                                        PastNoteChip(
                                            note: note,
                                            isSelected: Calendar.current.isDate(note.date, inSameDayAs: selectedDate)
                                        ) {
                                            selectedDate = note.date
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Napi napló")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddNote = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddDailyNoteSheet(defaultDate: selectedDate)
            }
            .sheet(item: $noteToEdit) { note in
                EditDailyNoteSheet(note: note)
            }
        }
    }
}


struct DailyNoteDetailView: View {
    let note: DailyNote
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(note.subject)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Tanulási napló")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Szerkesztés", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Törlés", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                        .foregroundStyle(.indigo)
                }
            }
            
            if !note.content.isEmpty {
                Divider()
                Text(note.content)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            
            if !note.studyGoals.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tanulási célok")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    ForEach(Array(note.studyGoals.enumerated()), id: \.offset) { _, goal in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                            Text(goal)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, 20)
        .confirmationDialog("Biztosan törlöd ezt a naplót?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Törlés", role: .destructive) { onDelete() }
            Button("Mégse", role: .cancel) {}
        }
    }
}


struct EditDailyNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let note: DailyNote
    
    @State private var subject: String
    @State private var content: String
    @State private var goals: [String]
    @State private var goalText = ""
    
    init(note: DailyNote) {
        self.note = note
        _subject = State(initialValue: note.subject)
        _content = State(initialValue: note.content)
        _goals   = State(initialValue: note.studyGoals)
    }
    
    private var canSave: Bool {
        !subject.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tantárgy") {
                    TextField("Pl. Matematika, Fizika...", text: $subject)
                }
                
                Section("Napló bejegyzés") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }
                
                Section("Tanulási célok") {
                    ForEach(goals, id: \.self) { goal in
                        Label(goal, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .onDelete { goals.remove(atOffsets: $0) }
                    
                    HStack {
                        TextField("Új cél hozzáadása...", text: $goalText)
                        Button("Hozzáad") {
                            let trimmed = goalText.trimmingCharacters(in: .whitespaces)
                            if !trimmed.isEmpty {
                                goals.append(trimmed)
                                goalText = ""
                            }
                        }
                        .foregroundStyle(.indigo)
                        .disabled(goalText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Napló szerkesztése")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Mégse") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mentés") {
                        note.subject    = subject.trimmingCharacters(in: .whitespaces)
                        note.content    = content
                        note.studyGoals = goals
                        try? modelContext.save()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}


struct DateScrollPicker: View {
    @Binding var selectedDate: Date
    
    private let days: [Date] = {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (-3...7).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
    }()
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(days, id: \.self) { day in
                        DayChip(date: day, isSelected: Calendar.current.isDate(day, inSameDayAs: selectedDate)) {
                            withAnimation(.spring(duration: 0.3)) {
                                selectedDate = day
                            }
                        }
                        .id(day)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
            .onAppear {
                proxy.scrollTo(Calendar.current.startOfDay(for: Date()), anchor: .center)
            }
        }
    }
}

struct DayChip: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
    
    private var dayName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateFormat = "EEE"
        return f.string(from: date)
    }
    
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                Text(dayNumber)
                    .font(.headline)
                    .fontWeight(.bold)
                if isToday {
                    Circle()
                        .fill(isSelected ? .white : .indigo)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 50, height: 64)
            .background(isSelected ? .indigo : Color(.secondarySystemGroupedBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay {
                if isToday && !isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(.indigo, lineWidth: 2)
                }
            }
        }
    }
}


struct EmptyDayView: View {
    let date: Date
    let onCreate: () -> Void
    
    private var isToday: Bool { Calendar.current.isDateInToday(date) }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 48))
                .foregroundStyle(.indigo.opacity(0.4))
            
            VStack(spacing: 6) {
                Text(isToday ? "Nincs mai bejegyzés" : "Nincs bejegyzés erre a napra")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("Rögzítsd a mai tanulási célokat és haladást!")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onCreate) {
                Label("Napló létrehozása", systemImage: "plus")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.indigo)
                    .clipShape(Capsule())
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
        .padding(.horizontal, 20)
    }
}


struct PastNoteChip: View {
    let note: DailyNote
    let isSelected: Bool
    let action: () -> Void
    
    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "hu_HU")
        f.dateFormat = "MMM d."
        return f.string(from: note.date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(dateString)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                Text(note.subject)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(width: 140, alignment: .leading)
            .background(isSelected ? .indigo : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}


struct AddDailyNoteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var defaultDate: Date
    
    @State private var subject = ""
    @State private var content = ""
    @State private var goalText = ""
    @State private var goals: [String] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tantárgy") {
                    TextField("Pl. Matematika, Fizika...", text: $subject)
                }
                
                Section("Napló bejegyzés") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                        .placeholder(when: content.isEmpty) {
                            Text("Mit tanultál ma? Milyen haladást értél el?")
                                .foregroundStyle(.tertiary)
                        }
                }
                
                Section("Tanulási célok") {
                    ForEach(goals, id: \.self) { goal in
                        Label(goal, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    HStack {
                        TextField("Új cél hozzáadása...", text: $goalText)
                        Button("Hozzáad") {
                            if !goalText.trimmingCharacters(in: .whitespaces).isEmpty {
                                goals.append(goalText.trimmingCharacters(in: .whitespaces))
                                goalText = ""
                            }
                        }
                        .foregroundStyle(.indigo)
                        .disabled(goalText.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
            .navigationTitle("Napi napló")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Mégse") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Mentés") {
                        let note = DailyNote(date: defaultDate, subject: subject, content: content, studyGoals: goals)
                        modelContext.insert(note)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(subject.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}


extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: .topLeading) {
            if shouldShow { placeholder().padding(.top, 8).padding(.leading, 4) }
            self
        }
    }
}

#Preview {
    DailyPlanView()
        .modelContainer(for: [Exam.self, DailyNote.self], inMemory: true)
}
