import SwiftUI

struct ReviewSessionView: View {
    @Environment(\.dismiss) private var dismiss
    let cards: [Flashcard]

    @State private var currentIndex = 0
    @State private var flipDegrees: Double = 0
    @State private var showingBack = false
    @State private var isDone = false
    @State private var againCount = 0
    @State private var goodCount = 0
    @State private var easyCount = 0

    private var current: Flashcard? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    private var progress: Double {
        guard !cards.isEmpty else { return 1 }
        return Double(currentIndex + 1) / Double(cards.count)
    }

    var body: some View {
        Group {
            if isDone || cards.isEmpty {
                SessionEndView(
                    total: cards.count,
                    againCount: againCount,
                    goodCount: goodCount,
                    easyCount: easyCount
                ) { dismiss() }
            } else {
                sessionContent
            }
        }
    }

    // MARK: - Session content

    private var sessionContent: some View {
        VStack(spacing: 0) {
            topBar
            ProgressView(value: progress)
                .tint(.accentColor)
                .padding(.horizontal)
                .padding(.top, 8)

            Spacer()

            if let card = current {
                flashCard(card)
                    .padding(.horizontal, 24)
                    .onTapGesture {
                        guard !showingBack else { return }
                        flipCard()
                    }
            }

            Spacer()

            if showingBack {
                responseButtons
                    .padding(.horizontal)
                    .padding(.bottom, 32)
            } else {
                Text("Touche la carte pour voir la réponse")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 32)
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(currentIndex + 1) / \(cards.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private func flashCard(_ card: Flashcard) -> some View {
        ZStack {
            CardFaceView(text: card.back, label: "Réponse")
                .opacity(showingBack ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))

            CardFaceView(text: card.front, label: "Question")
                .opacity(showingBack ? 0 : 1)
        }
        .rotation3DEffect(.degrees(flipDegrees), axis: (x: 0, y: 1, z: 0))
    }

    private var responseButtons: some View {
        HStack(spacing: 10) {
            SessionResponseButton(title: "À revoir", tint: Color(.systemRed)) {
                applyResponse(.again)
            }
            SessionResponseButton(title: "Correct", tint: Color(.systemGreen)) {
                applyResponse(.good)
            }
            SessionResponseButton(title: "Facile", tint: .accentColor) {
                applyResponse(.easy)
            }
        }
    }

    // MARK: - Logic

    private func flipCard() {
        withAnimation(.spring(duration: 0.5)) {
            flipDegrees = 180
        }
        Task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation {
                showingBack = true
            }
        }
    }

    private func applyResponse(_ response: ReviewResponse) {
        guard let card = current else { return }

        let result = SpacedRepetitionScheduler.schedule(
            easeFactor: card.easeFactor,
            interval: card.interval,
            repetitions: card.repetitions,
            response: response
        )
        card.easeFactor = result.easeFactor
        card.interval = result.interval
        card.repetitions = result.repetitions
        card.dueDate = result.dueDate

        switch response {
        case .again: againCount += 1
        case .good:  goodCount += 1
        case .easy:  easyCount += 1
        }

        advance()
    }

    private func advance() {
        let next = currentIndex + 1
        if next >= cards.count {
            withAnimation { isDone = true }
        } else {
            flipDegrees = 0
            showingBack = false
            currentIndex = next
        }
    }
}

// MARK: - Subviews

private struct CardFaceView: View {
    let text: String
    let label: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)

            VStack(spacing: 12) {
                Text(label.uppercased())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .tracking(1)
                Divider()
                    .padding(.horizontal, 24)
                Text(text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .padding(24)
        }
        .frame(minHeight: 240)
    }
}

private struct SessionResponseButton: View {
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(tint.opacity(0.12))
                .foregroundStyle(tint)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

private struct SessionEndView: View {
    let total: Int
    let againCount: Int
    let goodCount: Int
    let easyCount: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color("SemanticSuccess"))
                .padding(.bottom, 16)

            Text("Terminé pour aujourd'hui")
                .font(.title2.bold())
                .padding(.bottom, 8)

            Text("Bien joué. Tes prochaines cartes reviennent demain.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            statsBlock
                .padding(.horizontal)

            Spacer()

            Button("Fermer", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .padding(.bottom, 32)
        }
    }

    private var statsBlock: some View {
        VStack(spacing: 0) {
            StatRow(label: "Cartes révisées", value: "\(total)")
            if againCount > 0 {
                Divider().padding(.leading)
                StatRow(label: "À revoir", value: "\(againCount)", valueColor: Color(.systemRed))
            }
            if goodCount > 0 {
                Divider().padding(.leading)
                StatRow(label: "Correct", value: "\(goodCount)", valueColor: Color(.systemGreen))
            }
            if easyCount > 0 {
                Divider().padding(.leading)
                StatRow(label: "Facile", value: "\(easyCount)", valueColor: .accentColor)
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).foregroundStyle(valueColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
