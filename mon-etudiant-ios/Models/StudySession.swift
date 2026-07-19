import SwiftData
import Foundation

@Model
final class StudySession {
    var date: Date = Date()
    var duration: Double = 0.0 // en secondes

    var subject: Subject?

    init(date: Date = Date(), duration: Double = 0.0, subject: Subject? = nil) {
        self.date = date
        self.duration = duration
        self.subject = subject
    }
}
