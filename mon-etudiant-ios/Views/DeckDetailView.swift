import SwiftUI
import SwiftData

struct DeckDetailView: View {
    @Environment(\.modelContext) private var context
    let deck: Deck
    @Binding var isInReviewSession: Bool

    @State private var showAddCard = false
    @State private var cardToEdit: Flashcard?
    @State private var showEditDeck = false
    @State private var showSession = false

    private var sortedCards: [Flashcard] {
        (deck.cards ?? []).sorted { $0.front < $1.front }
    }

    var body: some View {
        List {
            if sortedCards.isEmpty {
                ContentUnavailableView(
                    "Aucune carte",
                    systemImage: "rectangle.stack",
                    description: Text("Ajoute des cartes à ce paquet pour commencer à réviser.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section("\(sortedCards.count) carte\(sortedCards.count > 1 ? "s" : "")") {
                    ForEach(sortedCards) { card in
                        CardRowView(card: card)
                            .contentShape(Rectangle())
                            .onTapGesture { cardToEdit = card }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    context.delete(card)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(deck.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Ajouter une carte", systemImage: "plus") {
                        showAddCard = true
                    }
                    Button("Modifier le paquet", systemImage: "pencil") {
                        showEditDeck = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !sortedCards.isEmpty {
                Button {
                    showSession = true
                } label: {
                    Label("Réviser ce paquet", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.regularMaterial)
            }
        }
        .sheet(isPresented: $showAddCard) {
            FlashcardFormView(deck: deck)
        }
        .sheet(item: $cardToEdit) { card in
            FlashcardFormView(deck: deck, card: card)
        }
        .sheet(isPresented: $showEditDeck) {
            DeckFormView(deck: deck)
        }
        .fullScreenCover(isPresented: $showSession) {
            ReviewSessionView(cards: sortedCards)
        }
        .onChange(of: showSession) { _, showing in
            isInReviewSession = showing
        }
    }
}

private struct CardRowView: View {
    let card: Flashcard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.front)
                .font(.headline)
                .lineLimit(2)
            Text(card.back)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }
}
