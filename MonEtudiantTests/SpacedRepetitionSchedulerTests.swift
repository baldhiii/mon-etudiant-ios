import Testing
import Foundation
@testable import mon_etudiant_ios

@Suite("SpacedRepetitionScheduler — SM-2")
struct SpacedRepetitionSchedulerTests {

    @Test("'À revoir' remet les répétitions à 0 et l'intervalle à 1")
    func againResetsCard() {
        let result = SpacedRepetitionScheduler.schedule(
            easeFactor: 2.5,
            interval: 6,
            repetitions: 2,
            response: .again
        )
        #expect(result.repetitions == 0)
        #expect(result.interval == 1)
        #expect(abs(result.easeFactor - 1.70) < 1e-9)
        #expect(result.dueDate > Date.now)
    }

    @Test("'Correct' sur première révision donne interval=1")
    func goodFirstReview() {
        let result = SpacedRepetitionScheduler.schedule(
            easeFactor: 2.5,
            interval: 1,
            repetitions: 0,
            response: .good
        )
        #expect(result.repetitions == 1)
        #expect(result.interval == 1)
        #expect(abs(result.easeFactor - 2.36) < 1e-9)
    }

    @Test("'Correct' sur deuxième révision donne interval=6")
    func goodSecondReview() {
        let result = SpacedRepetitionScheduler.schedule(
            easeFactor: 2.5,
            interval: 1,
            repetitions: 1,
            response: .good
        )
        #expect(result.repetitions == 2)
        #expect(result.interval == 6)
    }

    @Test("'Facile' sur troisième révision augmente l'EF et multiplie l'intervalle")
    func easyThirdReview() {
        let result = SpacedRepetitionScheduler.schedule(
            easeFactor: 2.5,
            interval: 6,
            repetitions: 2,
            response: .easy
        )
        #expect(result.repetitions == 3)
        #expect(result.interval == 15)
        #expect(abs(result.easeFactor - 2.6) < 1e-9)
    }
}
