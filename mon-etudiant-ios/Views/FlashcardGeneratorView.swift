import SwiftUI
import SwiftData

struct FlashcardGeneratorView: View {
    let subject: Subject

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var authService
    @Query private var profiles: [UserProfile]

    @State private var sourceText = ""
    @State private var count = 10
    @State private var isGenerating = false
    @State private var preview: [FlashcardsAIResponse.Card] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            if preview.isEmpty {
                inputStep
            } else {
                previewStep
            }
        }
    }

    // MARK: - Étape 1 : saisie du texte

    private var inputStep: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Stepper("Nombre de cartes : \(count)", value: $count, in: 5...20)
                } header: {
                    Text("Options")
                }

                Section {
                    TextEditor(text: $sourceText)
                        .frame(minHeight: 200)
                        .scrollContentBackground(.hidden)
                } header: {
                    Text("Texte source")
                } footer: {
                    Text("Colle ton cours ou tes notes.")
                }
            }

            if let msg = errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            Button(action: generate) {
                Group {
                    if isGenerating { ProgressView() }
                    else { Text("Générer \(count) flashcards") }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(trimmed.isEmpty || isGenerating)
            .padding()
        }
        .navigationTitle("Nouvelles flashcards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Annuler") { dismiss() }
            }
        }
    }

    // MARK: - Étape 2 : aperçu + import

    private var previewStep: some View {
        List {
            Section("Aperçu — \(preview.count) cartes") {
                ForEach(Array(preview.enumerated()), id: \.offset) { _, card in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.front)
                            .font(.body.weight(.medium))
                        Text(card.back)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Aperçu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Retour") { preview = [] }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Importer") {
                    importCards()
                }
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Helpers

    private var trimmed: String { sourceText.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func generate() {
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        isGenerating = true
        let level = profiles.first?.apiLevel ?? "lycee"
        Task {
            do {
                let response = try await APIClient.shared.generateFlashcards(
                    sourceText: trimmed, count: count, level: level
                )
                preview = response.cards
            } catch let e as APIError {
                errorMessage = e.errorDescription
                if e == .unauthorized { authService.signOut() }
            } catch {
                errorMessage = "Erreur réseau. Réessaie."
            }
            isGenerating = false
        }
    }

    private func importCards() {
        let deckName = "IA — \(subject.name)"
        let existing = (subject.decks ?? []).first(where: { $0.name == deckName })
        let deck: Deck
        if let d = existing {
            deck = d
        } else {
            deck = Deck(name: deckName, subject: subject)
            context.insert(deck)
        }
        for card in preview {
            context.insert(Flashcard(front: card.front, back: card.back, deck: deck))
        }
        dismiss()
    }
}
