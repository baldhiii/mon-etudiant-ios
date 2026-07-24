import SwiftUI
import SwiftData

struct FicheGeneratorView: View {
    let subject: Subject

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var authService
    @Query private var profiles: [UserProfile]

    @State private var sourceText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("Colle ici ton cours ou tes notes — l'IA génère une fiche structurée.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextEditor(text: $sourceText)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)
                    .frame(maxHeight: .infinity)

                if let msg = errorMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .padding(.top, 6)
                }

                Button(action: generate) {
                    Group {
                        if isGenerating {
                            ProgressView()
                        } else {
                            Text("Générer la fiche")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(trimmed.isEmpty || isGenerating)
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nouvelle fiche")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }

    private var trimmed: String { sourceText.trimmingCharacters(in: .whitespacesAndNewlines) }

    private func generate() {
        guard !trimmed.isEmpty else { return }
        errorMessage = nil
        isGenerating = true
        let level = profiles.first?.apiLevel ?? "lycee"
        Task {
            do {
                let response = try await APIClient.shared.generateFiche(sourceText: trimmed, level: level)
                let fiche = Fiche()
                fiche.title = response.title
                fiche.markdownContent = response.markdown
                fiche.subject = subject
                context.insert(fiche)
                dismiss()
            } catch let e as APIError {
                errorMessage = e.errorDescription
                if e == .unauthorized { authService.signOut() }
            } catch {
                errorMessage = "Erreur réseau. Réessaie."
            }
            isGenerating = false
        }
    }
}
