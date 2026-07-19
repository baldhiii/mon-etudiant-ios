import SwiftData
import Foundation

@Model
final class Flashcard {
    var front: String = ""
    var back: String = ""
    var easeFactor: Double = 2.5
    var interval: Int = 1
    var dueDate: Date = Date()
    var repetitions: Int = 0

    var deck: Deck?

    init(
        front: String = "",
        back: String = "",
        easeFactor: Double = 2.5,
        interval: Int = 1,
        dueDate: Date = Date(),
        repetitions: Int = 0,
        deck: Deck? = nil
    ) {
        self.front = front
        self.back = back
        self.easeFactor = easeFactor
        self.interval = interval
        self.dueDate = dueDate
        self.repetitions = repetitions
        self.deck = deck
    }
}
