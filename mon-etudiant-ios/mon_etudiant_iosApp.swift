import SwiftUI
import SwiftData

@main
struct mon_etudiant_iosApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Subject.self,
            CourseSession.self,
            Assignment.self,
            Exam.self,
            Deck.self,
            Flashcard.self,
            StudySession.self,
            UserProfile.self
        ])
        do {
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Impossible d'initialiser le ModelContainer : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
