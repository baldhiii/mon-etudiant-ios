import Testing
import Foundation
@testable import mon_etudiant_ios

// MARK: - SSEParser

@Suite("SSEParser — découpe arbitraire des chunks")
struct SSEParserTests {

    @Test("Découpe au milieu d'un objet JSON (chunks de 3 octets)")
    func chunkInMiddleOfJSON() async throws {
        let raw = "data: {\"delta\": \"Hello\"}\n\ndata: {\"done\": true}\n\n"
        let bytes = Array(raw.utf8)
        let chunks = stride(from: 0, to: bytes.count, by: 3)
            .map { Data(bytes[$0..<min($0 + 3, bytes.count)]) }
        var result: [String] = []
        for try await delta in SSEParser.stream(from: makeStream(chunks)) {
            result.append(delta)
        }
        #expect(result == ["Hello"])
    }

    @Test("è (U+00E8) coupé entre les deux octets UTF-8 0xC3 et 0xA8")
    func chunkInMiddleOfUTF8() async throws {
        // è encodes to [0xC3, 0xA8]; we deliberately split across chunk boundary
        let prefix = Array("data: {\"delta\": \"Tr".utf8)
        let suffix = Array("s\"}\n\ndata: {\"done\": true}\n\n".utf8)
        let chunks: [Data] = [
            Data(prefix + [0xC3]),
            Data([0xA8] + suffix)
        ]
        var result: [String] = []
        for try await delta in SSEParser.stream(from: makeStream(chunks)) {
            result.append(delta)
        }
        #expect(result == ["Très"])
    }

    @Test("Plusieurs deltas puis done dans un seul chunk")
    func multipleDeltasThenDone() async throws {
        let raw = "data: {\"delta\": \"Bon\"}\n\ndata: {\"delta\": \"jour\"}\n\ndata: {\"done\": true}\n\n"
        var result: [String] = []
        for try await delta in SSEParser.stream(from: makeStream([Data(raw.utf8)])) {
            result.append(delta)
        }
        #expect(result == ["Bon", "jour"])
    }

    @Test("Fin de flux sans événement done — le stream se ferme proprement")
    func streamClosesWithoutDone() async throws {
        let raw = "data: {\"delta\": \"Oui\"}\n\n"
        var result: [String] = []
        for try await delta in SSEParser.stream(from: makeStream([Data(raw.utf8)])) {
            result.append(delta)
        }
        #expect(result == ["Oui"])
    }
}

private func makeStream(_ chunks: [Data]) -> AsyncThrowingStream<UInt8, Error> {
    AsyncThrowingStream { continuation in
        Task {
            for chunk in chunks { for byte in chunk { continuation.yield(byte) } }
            continuation.finish()
        }
    }
}

// MARK: - APIError mapping

@Suite("APIError — correspondance codes HTTP")
struct APIErrorTests {

    @Test("401 → .unauthorized")
    func http401() {
        #expect(throws: APIError.unauthorized) { try makeResponse(401) }
    }

    @Test("429 → .quotaExceeded")
    func http429() {
        #expect(throws: APIError.quotaExceeded) { try makeResponse(429) }
    }

    @Test("503 → .aiUnavailable")
    func http503() {
        #expect(throws: APIError.aiUnavailable) { try makeResponse(503) }
    }

    @Test("200 → aucune erreur")
    func http200() {
        #expect(throws: Never.self) { try makeResponse(200) }
    }

    private func makeResponse(_ code: Int) throws {
        let url = URL(string: "https://example.com")!
        let resp = HTTPURLResponse(url: url, statusCode: code,
                                   httpVersion: nil, headerFields: nil)!
        try APIClient.shared.checkStatus(resp)
    }
}

// MARK: - TokenStore (Keychain round-trip)

@Suite("TokenStore — Keychain round-trip")
struct TokenStoreTests {

    @Test("save → load → delete")
    func roundTrip() throws {
        let token = "test_\(UUID().uuidString)"
        TokenStore.delete()            // état propre avant le test
        try TokenStore.save(token)
        #expect(TokenStore.load() == token)
        TokenStore.delete()
        #expect(TokenStore.load() == nil)
    }

    @Test("second save écrase le premier")
    func overwrite() throws {
        TokenStore.delete()
        try TokenStore.save("v1")
        try TokenStore.save("v2")
        let loaded = TokenStore.load()
        TokenStore.delete()
        #expect(loaded == "v2")
    }
}
