import SwiftData
import Foundation

@Model
final class UserProfile {
    var firstName: String = ""
    var schoolLevel: String = ""

    init(firstName: String = "", schoolLevel: String = "") {
        self.firstName = firstName
        self.schoolLevel = schoolLevel
    }
}
