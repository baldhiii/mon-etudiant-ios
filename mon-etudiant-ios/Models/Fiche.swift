import SwiftData
import Foundation

@Model
final class Fiche {
    var title: String = ""
    var markdownContent: String = ""
    var createdAt: Date = Date()

    // CloudKit : relation optionnelle avec deleteRule explicite
    @Relationship(deleteRule: .nullify) var subject: Subject?

    init() {}
}
