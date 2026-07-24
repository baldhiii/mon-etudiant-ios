import SwiftUI
import SwiftData

struct DeckFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \Subject.name) private var subjects: [Subject]

    var deck: Deck? = nil

    @State private var name = ""
    @State private var selectedSubject: Subject?

    private var isEditing: Bool { deck != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Paquet") {
                    TextField("Nom du paquet", text: $name)
                }
                Section("Matière (optionnel)") {
                    Picker("Matière", selection: $selectedSubject) {
                        Text("Aucune").tag(Optional<Subject>.none)
                        ForEach(subjects) { subject in
                            Text(subject.name).tag(Optional(subject))
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Modifier le paquet" : "Nouveau paquet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Enregistrer" : "Créer") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let deck {
                    name = deck.name
                    selectedSubject = deck.subject
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let deck {
            deck.name = trimmed
            deck.subject = selectedSubject
        } else {
            context.insert(Deck(name: trimmed, subject: selectedSubject))
        }
        dismiss()
    }
}
