import SwiftUI

struct AssignmentsView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                systemImage: "checklist",
                title: "Rien à faire",
                message: "Tout est à jour. Profite, ou prends de l'avance.",
                actionLabel: "Ajouter un devoir"
            ) {
                // Formulaire devoir — T2+
            }
            .navigationTitle("Devoirs")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Ajouter un devoir — T2+
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Ajouter un devoir")
                }
            }
        }
    }
}
