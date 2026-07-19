import SwiftUI

struct ReviewsView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                systemImage: "rectangle.stack.fill",
                title: "Aucun paquet",
                message: "Crée un paquet, ou demande au Professeur d'en générer un.",
                actionLabel: "Créer un paquet"
            ) {
                // Formulaire paquet — T2+
            }
            .navigationTitle("Révisions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Créer un paquet — T2+
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Créer un paquet")
                }
            }
        }
    }
}
