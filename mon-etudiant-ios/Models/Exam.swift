import SwiftData
import Foundation

@Model
final class Exam {
    var title: String = ""
    var date: Date = Date()
    var coefficient: Double = 1.0

    var subject: Subject?

    init(title: String = "", date: Date = Date(), coefficient: Double = 1.0, subject: Subject? = nil) {
        self.title = title
        self.date = date
        self.coefficient = coefficient
        self.subject = subject
    }
}
