import SwiftUI

struct AgendaView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                systemImage: "calendar",
                title: "Semaine vide",
                message: "Ajoute tes cours, ils apparaîtront ici jour par jour.",
                actionLabel: "Ajouter un cours"
            ) {
                // Formulaire cours — T2+
            }
            .navigationTitle("Agenda")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Matières") {
                        // Gestion des matières — T2+
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Ajouter un cours — T2+
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Ajouter un cours")
                }
            }
        }
    }
}
