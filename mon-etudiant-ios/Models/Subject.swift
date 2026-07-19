import SwiftData
import Foundation

@Model
final class Subject {
    var name: String = ""
    var colorName: String = "SubjectBlue"
    var level: String = ""
    var isArchived: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \CourseSession.subject)
    var sessions: [CourseSession]? = []

    @Relationship(deleteRule: .nullify, inverse: \Assignment.subject)
    var assignments: [Assignment]? = []

    @Relationship(deleteRule: .cascade, inverse: \Deck.subject)
    var decks: [Deck]? = []

    @Relationship(deleteRule: .nullify, inverse: \StudySession.subject)
    var studySessions: [StudySession]? = []

    @Relationship(deleteRule: .nullify, inverse: \Exam.subject)
    var exams: [Exam]? = []

    init(name: String = "", colorName: String = "SubjectBlue", level: String = "", isArchived: Bool = false) {
        self.name = name
        self.colorName = colorName
        self.level = level
        self.isArchived = isArchived
    }
}
