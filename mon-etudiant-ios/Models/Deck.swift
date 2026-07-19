import SwiftData
import Foundation

@Model
final class Deck {
    var name: String = ""

    var subject: Subject?

    @Relationship(deleteRule: .cascade, inverse: \Flashcard.deck)
    var cards: [Flashcard]? = []

    init(name: String = "", subject: Subject? = nil) {
        self.name = name
        self.subject = subject
    }
}
