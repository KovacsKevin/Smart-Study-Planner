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
 
    
    private var modelContext: ModelContext
 
    
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)
 
    
    var allNotes: [DailyNote] = []
 
    
    var showingAddNote = false
 
    
    var draftSubject  = ""
    var draftContent  = ""
    var draftGoalText = ""
    var draftGoals: [String] = []
 
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchNotes()
    }
 
    
 
    func fetchNotes() {
        let descriptor = FetchDescriptor<DailyNote>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        allNotes = (try? modelContext.fetch(descriptor)) ?? []
    }
 
    
 
   
    var noteForSelectedDate: DailyNote? {
        allNotes.first {
            Calendar.current.isDate($0.date, inSameDayAs: selectedDate)
        }
    }
 
    
    var isSelectedDateToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
 
    
 
    
    var recentNotes: [DailyNote] {
        Array(allNotes.prefix(10))
    }
 
    
 
    func selectDate(_ date: Date) {
        withAnimation(.spring(duration: 0.3)) {
            selectedDate = Calendar.current.startOfDay(for: date)
        }
    }
 
    func selectNoteDate(_ note: DailyNote) {
        selectDate(note.date)
    }
 
    
 
    func openAddNoteSheet() {
        resetDraft()
        showingAddNote = true
    }
 
    func dismissAddNoteSheet() {
        showingAddNote = false
        resetDraft()
    }
 
    
 
    private func resetDraft() {
        draftSubject  = ""
        draftContent  = ""
        draftGoalText = ""
        draftGoals    = []
    }
 
    
    func addDraftGoal() {
        let trimmed = draftGoalText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        draftGoals.append(trimmed)
        draftGoalText = ""
    }
 
    func removeDraftGoal(at offsets: IndexSet) {
        draftGoals.remove(atOffsets: offsets)
    }
 
    
    var canSaveDraft: Bool {
        !draftSubject.trimmingCharacters(in: .whitespaces).isEmpty
    }
 
    
 
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
 
    
 
    private func save() {
        try? modelContext.save()
    }
}
