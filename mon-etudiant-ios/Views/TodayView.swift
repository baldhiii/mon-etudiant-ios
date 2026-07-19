import SwiftUI

struct TodayView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Compteurs
                    HStack(spacing: 16) {
                        DashboardCounterCard(count: 0, label: "devoirs")
                        DashboardCounterCard(count: 0, label: "cartes")
                    }

                    // Prochains cours
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Prochains cours")
                            .font(.title2).bold()
                        Text("Pas de cours aujourd'hui.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // À rendre bientôt
                    VStack(alignment: .leading, spacing: 12) {
                        Text("À rendre bientôt")
                            .font(.title2).bold()
                        Text("Tout est à jour. Profite, ou prends de l'avance.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(16)
            }
            .navigationTitle("Aujourd'hui")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Réglages — T2+
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Réglages")
                }
            }
        }
    }
}

private struct DashboardCounterCard: View {
    let count: Int
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
