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

    // Conversion vers les identifiants API du backend
    var apiLevel: String {
        switch schoolLevel {
        case "Collège":            return "college"
        case "Lycée":              return "lycee"
        case "Études supérieures": return "universite"
        default:                   return "lycee"
        }
    }
}
