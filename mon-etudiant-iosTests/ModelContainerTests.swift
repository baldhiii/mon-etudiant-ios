import Testing
import SwiftData
@testable import mon_etudiant_ios

@Suite("ModelContainer CloudKit")
struct ModelContainerTests {

    @Test("Initialisation du ModelContainer compatible CloudKit")
    func containerInitializes() throws {
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
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        #expect(container != nil)
    }

    @Test("Insertion et lecture d'un Subject")
    @MainActor
    func insertAndFetchSubject() throws {
        let schema = Schema([
            Subject.self, CourseSession.self, Assignment.self,
            Exam.self, Deck.self, Flashcard.self,
            StudySession.self, UserProfile.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext

        let subject = Subject(name: "Mathématiques", colorName: "SubjectBlue", level: "Terminale")
        context.insert(subject)
        try context.save()

        let descriptor = FetchDescriptor<Subject>()
        let fetched = try context.fetch(descriptor)
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Mathématiques")
    }
}
