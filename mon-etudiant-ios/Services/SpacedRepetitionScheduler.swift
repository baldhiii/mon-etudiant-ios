import Foundation

enum ReviewResponse: Int {
    case again = 0  // À revoir
    case good  = 3  // Correct
    case easy  = 5  // Facile
}

struct ReviewResult {
    let easeFactor: Double
    let interval: Int
    let repetitions: Int
    let dueDate: Date
}

enum SpacedRepetitionScheduler {
    /// SM-2 adapté 3 réponses : again/good/easy.
    static func schedule(
        easeFactor: Double,
        interval: Int,
        repetitions: Int,
        response: ReviewResponse,
        now: Date = .now
    ) -> ReviewResult {
        let q = response.rawValue
        var ef = easeFactor
        var newInterval: Int
        var newReps: Int

        if q >= 3 {
            switch repetitions {
            case 0:  newInterval = 1
            case 1:  newInterval = 6
            default: newInterval = max(1, Int((Double(interval) * ef).rounded()))
            }
            newReps = repetitions + 1
        } else {
            newReps = 0
            newInterval = 1
        }

        let efDelta = 0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02)
        ef = max(1.3, ef + efDelta)

        let targetDate = Calendar.current.date(byAdding: .day, value: newInterval, to: now) ?? now
        let dueDate = Calendar.current.startOfDay(for: targetDate)

        return ReviewResult(
            easeFactor: ef,
            interval: newInterval,
            repetitions: newReps,
            dueDate: dueDate
        )
    }
}
