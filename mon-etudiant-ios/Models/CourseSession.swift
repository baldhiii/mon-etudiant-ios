import SwiftData
import Foundation

@Model
final class CourseSession {
    var dayOfWeek: Int = 2 // 2=lundi … 8=dimanche (Calendar.weekday)
    var startTime: Date = Date()
    var endTime: Date = Date()
    var room: String = ""
    var isRecurring: Bool = true

    var subject: Subject?

    init(
        dayOfWeek: Int = 2,
        startTime: Date = Date(),
        endTime: Date = Date(),
        room: String = "",
        isRecurring: Bool = true,
        subject: Subject? = nil
    ) {
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.room = room
        self.isRecurring = isRecurring
        self.subject = subject
    }
}
