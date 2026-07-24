import SwiftUI
import SwiftData

struct ReviewsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Deck.name) private var decks: [Deck]
    @Query private var allCards: [Flashcard]

    @Binding var isInReviewSession: Bool
    @State private var showDeckForm = false
    @State private var showSession = false
    @State private var sessionCards: [Flashcard] = []

    private var dueCards: [Flashcard] {
        let startOfTomorrow = Calendar.current.date(
            byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: .now)
        )!
        return allCards.filter { $0.dueDate < startOfTomorrow }
    }

    var body: some View {
        NavigationStack {
            Group {
                if decks.isEmpty {
                    EmptyStateView(
                        systemImage: "rectangle.stack.fill",
                        title: "Aucun paquet",
                        message: "Crée un paquet, ou demande au Professeur d'en générer un.",
                        actionLabel: "Créer un paquet"
                    ) {
                        showDeckForm = true
                    }
                } else {
                    deckList
                }
            }
            .navigationTitle("Révisions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Créer un paquet", systemImage: "folder.badge.plus") {
                            showDeckForm = true
                        }
                        Button("Demander à l'IA", systemImage: "sparkles") {
                            // Professeur — T5+
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Créer un paquet")
                }
            }
            .sheet(isPresented: $showDeckForm) {
                DeckFormView()
            }
            .fullScreenCover(isPresented: $showSession) {
                ReviewSessionView(cards: sessionCards)
            }
            .onChange(of: showSession) { _, showing in
                isInReviewSession = showing
            }
        }
    }

    private var deckList: some View {
        List {
            if !dueCards.isEmpty {
                Section {
                    DueCardsBannerView(count: dueCards.count) {
                        sessionCards = dueCards
                        showSession = true
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            Section("Mes paquets") {
                ForEach(decks) { deck in
                    NavigationLink {
                        DeckDetailView(deck: deck, isInReviewSession: $isInReviewSession)
                    } label: {
                        DeckRowView(deck: deck)
                    }
                }
                .onDelete(perform: deleteDecks)
            }
        }
    }

    private func deleteDecks(at offsets: IndexSet) {
        for index in offsets {
            context.delete(decks[index])
        }
    }
}

// MARK: - Subviews

private struct DueCardsBannerView: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(count) cartes à revoir")
                    .font(.headline)
                Text("5 minutes suffisent.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Button(action: action) {
                Label("Réviser maintenant", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

private struct DeckRowView: View {
    let deck: Deck

    private var cardCount: Int { deck.cards?.count ?? 0 }
    private var subjectColor: Color {
        if let name = deck.subject?.colorName { return Color(name) }
        return .accentColor
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(subjectColor)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(deck.name)
                    .font(.headline)
                if let subjectName = deck.subject?.name {
                    Text(subjectName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(cardCount)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
