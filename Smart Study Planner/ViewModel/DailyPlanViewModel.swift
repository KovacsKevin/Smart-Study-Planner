//
//  DailyPlanViewModel.swift
//  Smart Study Planner
//
//  Created by Kevin on 2026. 05. 22..
//
import SwiftUI
import SwiftData

@MainActor
@Observable
final class DailyPlanViewModel {
 
    // MARK: Dependencies
    private var modelContext: ModelContext
 
    // MARK: State – dátumválasztó
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)
 
    // MARK: State – naplók
    var allNotes: [DailyNote] = []
 
    // MARK: State – sheet
    var showingAddNote = false
 
    // MARK: State – AddNoteSheet mezők
    var draftSubject  = ""
    var draftContent  = ""
    var draftGoalText = ""
    var draftGoals: [String] = []
 
    // MARK: Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchNotes()
    }
 
    // MARK: - Fetch
 
    func fetchNotes() {
        let descriptor = FetchDescriptor<DailyNote>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        allNotes = (try? modelContext.fetch(descriptor)) ?? []
    }
 
    // MARK: - Computed: kiválasztott nap bejegyzése
 
    /// A DateScrollPicker által kiválasztott naphoz tartozó napló (vagy nil)
    var noteForSelectedDate: DailyNote? {
        allNotes.first {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
 
    /// Igaz, ha a kiválasztott nap a mai nap
    var isSelectedDateToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
 
    // MARK: - Computed: korábbi naplók (horizontal scroll)
 
    /// Legfeljebb 10 korábbi bejegyzés (AddNote sheet-hez és PastNoteChip-hez)
    var recentNotes: [DailyNote] {
        Array(allNotes.prefix(10))
    }
 
    // MARK: - Dátum kiválasztása
 
    func selectDate(_ date: Date) {
        withAnimation(.spring(duration: 0.3)) {
            selectedDate = Calendar.current.startOfDay(for: date)
        }
    }
 
    func selectNoteDate(_ note: DailyNote) {
        selectDate(note.date)
    }
 
    // MARK: - Sheet megnyitása / zárása
 
    func openAddNoteSheet() {
        resetDraft()
        showingAddNote = true
    }
 
    func dismissAddNoteSheet() {
        showingAddNote = false
        resetDraft()
    }
 
    // MARK: - Draft kezelés (AddDailyNoteSheet)
 
    private func resetDraft() {
        draftSubject  = ""
        draftContent  = ""
        draftGoalText = ""
        draftGoals    = []
    }
 
    /// "Hozzáad" gomb a goal inputhoz
    func addDraftGoal() {
        let trimmed = draftGoalText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        draftGoals.append(trimmed)
        draftGoalText = ""
    }
 
    func removeDraftGoal(at offsets: IndexSet) {
        draftGoals.remove(atOffsets: offsets)
    }
 
    /// Igaz, ha a "Mentés" gomb aktív
    var canSaveDraft: Bool {
        !draftSubject.trimmingCharacters(in: .whitespaces).isEmpty
    }
 
    // MARK: - Mentés
 
    func saveDraftNote(for date: Date) {
        guard canSaveDraft else { return }
        let note = DailyNote(
            date: date,
            subject: draftSubject.trimmingCharacters(in: .whitespaces),
            content: draftContent,
            studyGoals: draftGoals
        )
        modelContext.insert(note)
        save()
        fetchNotes()
        dismissAddNoteSheet()
    }
 
    // MARK: - Törlés
 
    func deleteNote(_ note: DailyNote) {
        modelContext.delete(note)
        save()
        fetchNotes()
    }
 
    func deleteNotes(at offsets: IndexSet, from list: [DailyNote]) {
        offsets.map { list[$0] }.forEach { modelContext.delete($0) }
        save()
        fetchNotes()
    }
 
    // MARK: - Persistence
 
    private func save() {
        try? modelContext.save()
    }
}
