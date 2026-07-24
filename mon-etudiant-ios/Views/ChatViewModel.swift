import Foundation
import Observation

@Observable @MainActor
final class ChatViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isWaiting: Bool = false     // avant le 1er delta
    var isStreaming: Bool = false   // pendant toute la durée du stream
    var errorState: APIError?
    var quota: QuotaResponse?

    var userLevel: String = "lycee"
    var subject: String?

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isStreaming else { return }

        inputText = ""
        errorState = nil
        quota = nil

        messages.append(ChatMessage(role: "user", content: text))
        messages.append(ChatMessage(role: "assistant", content: ""))
        let idx = messages.count - 1

        // Backend limite à 20 tours — on tronque ici aussi pour cohérence
        let history = Array(messages.dropLast().suffix(20))
        let level = userLevel
        let subj = subject

        isWaiting = true
        isStreaming = true

        Task {
            do {
                var gotFirst = false
                for try await delta in APIClient.shared.chatStream(
                    messages: history, level: level, subject: subj
                ) {
                    if !gotFirst { isWaiting = false; gotFirst = true }
                    messages[idx].content += delta
                }
            } catch let e as APIError {
                messages.removeLast()   // retire la bulle assistante vide
                errorState = e
                if e == .quotaExceeded {
                    quota = try? await APIClient.shared.fetchQuota()
                }
            } catch {
                messages.removeLast()
                errorState = .network(URLError(.notConnectedToInternet))
            }
            isWaiting = false
            isStreaming = false
        }
    }

    func retry() {
        errorState = nil
        quota = nil
    }

    func clearHistory() {
        messages = []
        errorState = nil
        quota = nil
    }
}
