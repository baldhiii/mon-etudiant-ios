import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        // /me/quota renvoie resets_at en ISO 8601 avec ou sans fractions de secondes
        let full = ISO8601DateFormatter()
        full.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let short = ISO8601DateFormatter()
        short.formatOptions = [.withInternetDateTime]
        d.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            if let date = full.date(from: s)  { return date }
            if let date = short.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Invalid date: \(s)")
        }
        return d
    }()

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = 70   // cold-start Render ~60 s
        config.timeoutIntervalForResource = 300
        session = URLSession(configuration: config)
    }

    // MARK: - Auth

    func signInWithApple(identityToken: String) async throws -> AuthResponse {
        try await request(
            method: "POST", path: "/api/v1/auth/apple",
            body: ["identity_token": identityToken],
            authenticated: false
        )
    }

    // MARK: - Quota

    func fetchQuota() async throws -> QuotaResponse {
        try await request(method: "GET", path: "/api/v1/me/quota")
    }

    // MARK: - Chat (SSE)

    func chatStream(
        messages: [ChatMessage],
        level: String,
        subject: String? = nil
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var body: [String: Any] = [
                        "messages": messages.map { ["role": $0.role, "content": $0.content] },
                        "level": level
                    ]
                    if let subject { body["subject"] = subject }
                    var req = try buildRequest(method: "POST", path: "/api/v1/ai/chat", body: body)
                    req.timeoutInterval = 0   // pas de timeout sur le streaming
                    let (bytes, response) = try await session.bytes(for: req)
                    try checkStatus(response)
                    for try await delta in SSEParser.stream(from: bytes) {
                        continuation.yield(delta)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: toAPIError(error))
                }
            }
        }
    }

    // MARK: - Flashcards

    func generateFlashcards(
        sourceText: String,
        count: Int = 10,
        level: String
    ) async throws -> FlashcardsAIResponse {
        try await request(
            method: "POST", path: "/api/v1/ai/flashcards",
            body: ["source_text": sourceText, "count": count, "level": level]
        )
    }

    // MARK: - Fiche de révision

    func generateFiche(sourceText: String, level: String) async throws -> FicheResponse {
        try await request(
            method: "POST", path: "/api/v1/ai/fiche",
            body: ["source_text": sourceText, "level": level]
        )
    }

    // MARK: - Private helpers

    private func request<T: Decodable>(
        method: String,
        path: String,
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        let req = try buildRequest(method: method, path: path, body: body, authenticated: authenticated)
        let (data, response) = try await withRetry { [self] in
            try await session.data(for: req)
        }
        try checkStatus(response, data: data)
        do {
            return try Self.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding
        }
    }

    /// Rejoue automatiquement l'opération une fois sur les échecs de connexion
    /// (cas typique : cold-start Render ou perte réseau transitoire).
    private func withRetry<T>(_ op: () async throws -> T) async throws -> T {
        do {
            return try await op()
        } catch let err as URLError
            where err.code == .cannotConnectToHost
               || err.code == .networkConnectionLost
               || err.code == .timedOut {
            return try await op()
        }
    }

    private func buildRequest(
        method: String,
        path: String,
        body: [String: Any]? = nil,
        authenticated: Bool = true
    ) throws -> URLRequest {
        let base = AppEnvironment.baseURL.absoluteString
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + path) else { throw URLError(.badURL) }
        var request = URLRequest(url: url, timeoutInterval: 70)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated, let token = TokenStore.load() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }

    // Internal (not private) so that unit tests can call it via @testable import
    func checkStatus(_ response: URLResponse, data: Data? = nil) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: return
        case 401:       throw APIError.unauthorized
        case 429:       throw APIError.quotaExceeded
        case 503:       throw APIError.aiUnavailable
        default:        throw APIError.network(URLError(.badServerResponse))
        }
    }

    private func toAPIError(_ error: Error) -> APIError {
        if let e = error as? APIError { return e }
        if let e = error as? URLError { return .network(e) }
        return .network(URLError(.unknown))
    }
}
