import SwiftUI
import AuthenticationServices

struct ProfessorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    var body: some View {
        if authService.isAuthenticated {
            chatPlaceholder
        } else {
            ProfessorSignInView()
        }
    }

    // Placeholder conservé — T7 implémentera le vrai chat SSE
    private var chatPlaceholder: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                Text("Ton Professeur est là")
                    .font(.title2).bold()
                Text("Pose une question, il te guide pas à pas, sans donner la réponse toute faite.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Professeur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Écran de connexion

private struct ProfessorSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthService.self) private var authService

    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.accentColor)

                    Text("Ton Professeur est là")
                        .font(.title2.bold())

                    Text("Pose une question, il te guide pas à pas, sans donner la réponse toute faite.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                VStack(spacing: 16) {
                    if isSigningIn {
                        ProgressView()
                            .frame(height: 50)
                    } else {
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName]
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .frame(maxWidth: 280)
                    }

                    if let msg = errorMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Text("Tes cours et devoirs restent sur ton iPhone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 48)
            }
            .navigationTitle("Professeur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        errorMessage = nil
        guard case .success(let auth) = result,
              let credential = auth.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let identityToken = String(data: tokenData, encoding: .utf8)
        else {
            if case .failure = result {
                errorMessage = "Connexion annulée ou échouée."
            }
            return
        }

        isSigningIn = true
        Task {
            do {
                let response = try await APIClient.shared.signInWithApple(identityToken: identityToken)
                authService.didSignIn(token: response.accessToken)
            } catch {
                errorMessage = (error as? APIError)?.errorDescription ?? "Connexion impossible. Réessaie."
            }
            isSigningIn = false
        }
    }
}
