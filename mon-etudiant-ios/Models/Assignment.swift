import SwiftData
import Foundation

// reminderType: 0 = aucun, 1 = J-1, 2 = jour J
@Model
final class Assignment {
    var title: String = ""
    var dueDate: Date = Date()
    var priority: Int = 0
    var progress: Double = 0.0
    var isDone: Bool = false
    var note: String = ""
    var reminderType: Int = 0

    var subject: Subject?

    init(
        title: String = "",
        dueDate: Date = Date(),
        priority: Int = 0,
        progress: Double = 0.0,
        isDone: Bool = false,
        note: String = "",
        reminderType: Int = 0,
        subject: Subject? = nil
    ) {
        self.title = title
        self.dueDate = dueDate
        self.priority = priority
        self.progress = progress
        self.isDone = isDone
        self.note = note
        self.reminderType = reminderType
        self.subject = subject
    }
}
