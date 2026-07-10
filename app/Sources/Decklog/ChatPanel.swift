import SwiftUI
import MarkdownUI

/// The PM agent chat panel: transcript + input box. Sending a message runs a headless
/// Claude Code turn; on completion the host commits and reloads the bundle.
struct ChatPanel: View {
    @ObservedObject var session: PMAgentSession
    @State private var draft = ""
    @State private var inputHeight: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header
                Divider()
                transcript
                Divider()
                if !pendingOptions.isEmpty { optionsBar }
                inputBar(maxHeight: max(geo.size.height * 0.5, 28))
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 8) {
            Label("PM agent", systemImage: "bubble.left.and.text.bubble.right")
                .font(.headline)
            Spacer()
            if session.isRunning { ProgressView().controlSize(.small) }
        }
        .padding(10)
    }

    private var transcript: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(session.messages) { message in
                        MessageRow(message: message).id(message.id)
                    }
                    if session.isRunning {
                        ThinkingRow().id(Self.thinkingID)
                    }
                }
                .padding(10)
            }
            .onChange(of: session.messages.count) { _ in scrollToEnd(proxy) }
            .onChange(of: session.isRunning) { _ in scrollToEnd(proxy) }
        }
    }

    private static let thinkingID = "thinking-indicator"

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation {
            if session.isRunning {
                proxy.scrollTo(Self.thinkingID, anchor: .bottom)
            } else if let last = session.messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private func inputBar(maxHeight: CGFloat) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            ChatInputView(
                text: $draft,
                height: $inputHeight,
                isEnabled: !session.isRunning,
                onSubmit: send
            )
            .frame(height: min(inputHeight, maxHeight))
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.return, modifiers: [.command]) // ⌘↩ also sends
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || session.isRunning)
        }
        .padding(10)
    }

    /// Options offered by the latest assistant question (empty otherwise).
    private var pendingOptions: [String] {
        guard !session.isRunning, let last = session.messages.last, last.role == .assistant
        else { return [] }
        return ChatOptions.parse(last.text).options
    }

    private var optionsBar: some View {
        VStack(spacing: 6) {
            ForEach(pendingOptions, id: \.self) { option in
                Button {
                    session.send(option)
                } label: {
                    Text(option)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
    }

    private func send() {
        let text = draft
        draft = ""
        session.send(text)
    }
}

/// Parses a trailing ```decklog:options … ``` block from an assistant message into
/// selectable options, returning the message text with that block removed.
enum ChatOptions {
    static func parse(_ text: String) -> (display: String, options: [String]) {
        let lines = text.components(separatedBy: "\n")
        guard let start = lines.firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces) == "```decklog:options"
        }) else { return (text, []) }
        guard let end = lines[(start + 1)...].firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces) == "```"
        }) else { return (text, []) }

        let options = lines[(start + 1)..<end]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let display = (lines[..<start] + lines[(end + 1)...])
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (display, options)
    }
}

private struct MessageRow: View {
    let message: PMAgentSession.Message

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 32)
                Text(message.text)
                    .textSelection(.enabled)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.accentColor.opacity(0.22)))
            }
        case .assistant:
            // Rendered markdown; any decklog:options block is stripped (shown as buttons).
            Markdown(ChatOptions.parse(message.text).display)
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
        case .activity:
            Label(message.text, systemImage: "wrench.and.screwdriver")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .error:
            Label(message.text, systemImage: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .textSelection(.enabled)
        }
    }
}

/// Shown while a turn is in flight — covers the gap before any text/activity streams in.
private struct ThinkingRow: View {
    @State private var pulse = false

    var body: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Thinking…")
                .font(.callout)
                .foregroundStyle(.secondary)
                .opacity(pulse ? 0.4 : 1)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
            Spacer(minLength: 0)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
        .onAppear { pulse = true }
    }
}
