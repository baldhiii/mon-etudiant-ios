import Foundation

/// Parses Server-Sent Events from the /ai/chat endpoint.
///
/// Buffers incomplete lines across TCP chunk boundaries and handles
/// split UTF-8 multi-byte sequences (the line buffer accumulates raw bytes
/// and decodes only on '\n', so a split character is always reassembled
/// before String conversion).
enum SSEParser {

    // MARK: - Public overloads

    /// Parse SSE from a live URLSession byte stream (production path).
    static func stream(from bytes: URLSession.AsyncBytes) -> AsyncThrowingStream<String, Error> {
        stream(from: erase(bytes))
    }

    /// Parse SSE from a throwing byte stream — used by unit tests and other callers.
    static func stream(from bytes: AsyncThrowingStream<UInt8, Error>) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                var lineBuffer = Data()
                do {
                    for try await byte in bytes {
                        if byte == UInt8(ascii: "\n") {
                            // Strip optional '\r' for CRLF line endings
                            if lineBuffer.last == UInt8(ascii: "\r") { lineBuffer.removeLast() }
                            if !lineBuffer.isEmpty {
                                emit(lineBuffer, into: continuation)
                                lineBuffer.removeAll(keepingCapacity: true)
                            }
                            // blank line (event separator) — no action needed
                        } else {
                            lineBuffer.append(byte)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Internals

    /// Type-erase URLSession.AsyncBytes into a throwing stream of UInt8.
    private static func erase(_ bytes: URLSession.AsyncBytes) -> AsyncThrowingStream<UInt8, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await byte in bytes { continuation.yield(byte) }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Decode one SSE "data:" line and push to the continuation.
    private static func emit(
        _ lineData: Data,
        into continuation: AsyncThrowingStream<String, Error>.Continuation
    ) {
        guard let line = String(data: lineData, encoding: .utf8),
              line.hasPrefix("data: ") else { return }
        let payload = String(line.dropFirst(6))
        guard let payloadData = payload.data(using: .utf8),
              let event = try? JSONDecoder().decode(SSEEvent.self, from: payloadData)
        else { return }

        if event.done == true {
            continuation.finish()
        } else if let delta = event.delta {
            continuation.yield(delta)
        }
    }
}

private struct SSEEvent: Decodable {
    let delta: String?
    let done:  Bool?
}
