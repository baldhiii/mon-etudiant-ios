import Foundation
import Observation

@Observable
final class AuthService {
    private(set) var accessToken: String?

    init() {
        accessToken = TokenStore.load()
    }

    var isAuthenticated: Bool { accessToken != nil }

    /// Called after a successful Sign in with Apple → POST /auth/apple round-trip.
    func didSignIn(token: String) {
        try? TokenStore.save(token)
        accessToken = token
    }

    /// DEV-mode shortcut: paste a forged token without going through Apple.
    func setToken(_ token: String) {
        try? TokenStore.save(token)
        accessToken = token
    }

    /// Purge token from memory and Keychain.
    /// Called on explicit sign-out or on receiving a 401 from the server.
    func signOut() {
        TokenStore.delete()
        accessToken = nil
    }
}
