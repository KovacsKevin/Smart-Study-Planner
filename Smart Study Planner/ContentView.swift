
	
import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Áttekintés", systemImage: "house.fill")
                }
            
            ExamsView()
                .tabItem {
                    Label("Vizsgák", systemImage: "calendar")
                }
            
            DailyPlanView()
                .tabItem {
                    Label("Mai terv", systemImage: "note.text")
                }
            
            SemesterView()
                .tabItem {
                    Label("Félév", systemImage: "chart.bar.fill")
                }
            
            NotificationsView()
                .tabItem {
                    Label("Értesítők", systemImage: "bell.fill")
                }
        }
        .accentColor(.indigo)
    }	
}

#Preview {
    let container = try! ModelContainer(
        for: Exam.self, DailyNote.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    let ctx = container.mainContext

    
    ctx.insert(Exam(subject: "Matematika", date: .now.addingTimeInterval(86400 * 2), priority: .high))
    ctx.insert(Exam(subject: "Fizika", date: .now.addingTimeInterval(86400 * 5), priority: .high))

    
    ctx.insert(Exam(subject: "Történelem", date: .now.addingTimeInterval(86400 * 10), priority: .medium))
    ctx.insert(Exam(subject: "Kémia", date: .now.addingTimeInterval(86400 * 14), priority: .medium))

    
    ctx.insert(Exam(subject: "Testnevelés", date: .now.addingTimeInterval(86400 * 20), priority: .low))

    
    let completed = Exam(subject: "Irodalom", date: .now.addingTimeInterval(-86400 * 3), priority: .medium)
    completed.isCompleted = true
    ctx.insert(completed)

    return ContentView()
        .modelContainer(container)
}

