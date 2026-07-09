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

    private func send() {
        let text = draft
        draft = ""
        session.send(text)
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
            // Rendered markdown, filling the column width.
            Markdown(message.text)
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
