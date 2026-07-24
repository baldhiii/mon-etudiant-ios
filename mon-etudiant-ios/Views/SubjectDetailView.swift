import SwiftUI
import SwiftData

struct SubjectDetailView: View {
    let subject: Subject
    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var authService

    @State private var showFicheGenerator = false
    @State private var showFlashcardGenerator = false
    @State private var showEditSubject = false
    @State private var deleteFicheTarget: Fiche?

    private var fiches: [Fiche] {
        (subject.fiches ?? []).sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        List {
            aiSection
            if !fiches.isEmpty { fichesSection }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(subject.name)
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: Fiche.self) { fiche in
            FicheDetailView(fiche: fiche)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEditSubject = true } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showFicheGenerator) {
            FicheGeneratorView(subject: subject)
        }
        .sheet(isPresented: $showFlashcardGenerator) {
            FlashcardGeneratorView(subject: subject)
        }
        .sheet(isPresented: $showEditSubject) {
            SubjectFormView(subject: subject)
        }
        .confirmationDialog(
            "Supprimer cette fiche ?",
            isPresented: Binding(
                get: { deleteFicheTarget != nil },
                set: { if !$0 { deleteFicheTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                if let f = deleteFicheTarget { context.delete(f) }
                deleteFicheTarget = nil
            }
        }
    }

    // MARK: - Sections

    private var aiSection: some View {
        Section("Intelligence artificielle") {
            Button {
                showFicheGenerator = true
            } label: {
                Label("Générer une fiche", systemImage: "doc.text.magnifyingglass")
            }
            Button {
                showFlashcardGenerator = true
            } label: {
                Label("Générer des flashcards", systemImage: "rectangle.stack.badge.plus")
            }
        }
    }

    private var fichesSection: some View {
        Section("Fiches (\(fiches.count))") {
            ForEach(fiches) { fiche in
                NavigationLink(value: fiche) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(fiche.title)
                            .font(.body)
                        Text(fiche.createdAt, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        deleteFicheTarget = fiche
                    } label: {
                        Label("Supprimer", systemImage: "trash")
                    }
                }
            }
        }
    }
}
