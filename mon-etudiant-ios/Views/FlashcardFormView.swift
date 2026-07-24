import SwiftUI
import SwiftData

struct FlashcardFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let deck: Deck
    var card: Flashcard? = nil

    @State private var front = ""
    @State private var back = ""

    private var isEditing: Bool { card != nil }
    private var canSave: Bool {
        !front.trimmingCharacters(in: .whitespaces).isEmpty &&
        !back.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Question (recto)") {
                    TextField("Ex. : Quelle est la formule de l'énergie cinétique ?", text: $front, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section("Réponse (verso)") {
                    TextField("Ex. : Ec = ½mv²", text: $back, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Modifier la carte" : "Nouvelle carte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Ajouter") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                if let card {
                    front = card.front
                    back = card.back
                }
            }
        }
    }

    private func save() {
        let f = front.trimmingCharacters(in: .whitespaces)
        let b = back.trimmingCharacters(in: .whitespaces)
        if let card {
            card.front = f
            card.back = b
        } else {
            context.insert(Flashcard(front: f, back: b, deck: deck))
        }
        dismiss()
    }
}
