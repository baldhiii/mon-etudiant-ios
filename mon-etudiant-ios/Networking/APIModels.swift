import Foundation

// MARK: - Shared request type

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    var role: String    // "user" | "assistant"
    var content: String

    init(role: String, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
    }

    // id is local-only — not part of the API payload
    enum CodingKeys: CodingKey { case role, content }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id      = UUID()
        role    = try c.decode(String.self, forKey: .role)
        content = try c.decode(String.self, forKey: .content)
    }
}

// MARK: - Response models

struct AuthResponse: Decodable {
    let accessToken: String
    let userId: String
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case userId      = "user_id"
    }
}

struct QuotaResponse: Decodable {
    let usedToday:  Int
    let dailyLimit: Int
    let resetsAt:   Date
    enum CodingKeys: String, CodingKey {
        case usedToday  = "used_today"
        case dailyLimit = "daily_limit"
        case resetsAt   = "resets_at"
    }
}

struct FlashcardsAIResponse: Decodable {
    struct Card: Decodable { let front: String; let back: String }
    let cards: [Card]
}

struct FicheResponse: Decodable {
    let title: String
    let markdown: String
}

// MARK: - Error types

enum APIError: Error, LocalizedError, Equatable {
    case unauthorized
    case quotaExceeded
    case aiUnavailable
    case network(URLError)
    case decoding

    var errorDescription: String? {
        switch self {
        case .unauthorized:  return "Session expirée. Reconnecte-toi."
        case .quotaExceeded: return "Quota quotidien atteint. Réessaie demain."
        case .aiUnavailable: return "Le Professeur est temporairement indisponible."
        case .network:       return "Connexion requise pour le Professeur."
        case .decoding:      return "Erreur de communication avec le serveur."
        }
    }

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized,  .unauthorized),
             (.quotaExceeded, .quotaExceeded),
             (.aiUnavailable, .aiUnavailable),
             (.decoding,      .decoding):       return true
        case (.network(let a), .network(let b)): return a.code == b.code
        default:                                 return false
        }
    }
}

// Used only to parse error bodies from the server (not thrown directly)
struct APIErrorBody: Decodable {
    struct Detail: Decodable { let code: String; let message: String }
    let error: Detail
}
