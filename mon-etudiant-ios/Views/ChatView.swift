import SwiftUI
import SwiftData

struct ChatView: View {
    @Environment(AuthService.self) private var authService
    @Query private var profiles: [UserProfile]

    @State private var viewModel = ChatViewModel()

    // Contexte optionnel transmis par SubjectDetailView
    var subjectName: String? = nil

    var body: some View {
        VStack(spacing: 0) {
            messagesArea
            errorBanner
            inputBar
        }
        .onAppear {
            viewModel.userLevel = profiles.first?.apiLevel ?? "lycee"
            viewModel.subject = subjectName
        }
        .onChange(of: viewModel.errorState) { _, newError in
            // 401 → déconnexion → ProfessorView bascule sur ProfessorSignInView
            if newError == .unauthorized { authService.signOut() }
        }
    }

    // MARK: - Messages

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyHint
                    }
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if viewModel.isWaiting {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: viewModel.isWaiting) { _, _ in
                scrollToBottom(proxy)
            }
        }
    }

    private var emptyHint: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.accent)
            Text("Pose une question,\nil te guide sans donner la réponse toute faite.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if viewModel.isWaiting {
            withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
        } else if let last = viewModel.messages.last {
            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
        }
    }

    // MARK: - Error banner

    @ViewBuilder
    private var errorBanner: some View {
        if let error = viewModel.errorState, error != .unauthorized {
            HStack(spacing: 10) {
                Image(systemName: errorIcon(for: error))
                    .foregroundStyle(errorColor(for: error))
                VStack(alignment: .leading, spacing: 2) {
                    Text(error.errorDescription ?? "Erreur")
                        .font(.footnote.weight(.semibold))
                    if error == .quotaExceeded, let q = viewModel.quota {
                        Text("Réinitialisé dans \(resetIn(q.resetsAt))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if error == .aiUnavailable {
                    Button("Réessayer") { viewModel.retry() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(errorColor(for: error).opacity(0.12))
        }
    }

    private func errorIcon(for error: APIError) -> String {
        switch error {
        case .quotaExceeded: return "chart.bar.fill"
        case .aiUnavailable: return "wifi.slash"
        case .network:       return "antenna.radiowaves.left.and.right.slash"
        default:             return "exclamationmark.triangle"
        }
    }

    private func errorColor(for error: APIError) -> Color {
        switch error {
        case .quotaExceeded: return .orange
        case .aiUnavailable, .network: return .red
        default: return .orange
        }
    }

    private func resetIn(_ date: Date) -> String {
        let diff = max(0, date.timeIntervalSinceNow)
        let hours = Int(diff / 3600)
        let minutes = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 { return "\(hours) h" }
        if minutes > 0 { return "\(minutes) min" }
        return "bientôt"
    }

    // MARK: - Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Pose ta question…", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isStreaming)

            Button(action: viewModel.sendMessage) {
                Image(systemName: viewModel.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(canSend ? Color.accentColor : .secondary)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var canSend: Bool {
        !viewModel.isStreaming && !viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

// MARK: - Message bubble

private struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            if isUser { Spacer(minLength: 48) }
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    isUser ? Color.accentColor : Color(.secondarySystemFill),
                    in: RoundedRectangle(cornerRadius: 18)
                )
            if !isUser { Spacer(minLength: 48) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
    }

    @ViewBuilder
    private var content: some View {
        if isUser {
            Text(message.content)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        } else if message.content.isEmpty {
            // Bulle en attente du premier delta (ne devrait pas s'afficher — voir TypingIndicator)
            Text(" ")
        } else {
            markdownText
                .multilineTextAlignment(.leading)
        }
    }

    private var markdownText: some View {
        Group {
            if let attr = try? AttributedString(
                markdown: message.content,
                options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                Text(attr)
            } else {
                Text(message.content)
            }
        }
    }
}

// MARK: - Typing indicator

struct TypingIndicatorView: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(.tertiaryLabel))
                    .frame(width: 8, height: 8)
                    .scaleEffect(phase == i ? 1.3 : 0.85)
                    .animation(.easeInOut(duration: 0.38).repeatForever(autoreverses: true), value: phase)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 18))
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            Task {
                while !Task.isCancelled {
                    withAnimation { phase = (phase + 1) % 3 }
                    try? await Task.sleep(nanoseconds: 380_000_000)
                }
            }
        }
    }
}
