import Foundation
import OKFKit

/// Drives a headless Claude Code process as the PM chat agent, scoped to the bundle
/// repo. Multi-turn via a stable `--session-id` / `--resume`. Parses `stream-json`
/// (JSONL) output into chat messages.
///
/// macOS-only runtime; not compiled/verified off macOS.
@MainActor
final class PMAgentSession: ObservableObject {

    struct Message: Identifiable {
        enum Role { case user, assistant, activity, error }
        let id = UUID()
        let role: Role
        var text: String
    }

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isRunning = false

    /// Invoked after a completed turn, with a suggested commit message.
    var onTurnComplete: ((String) -> Void)?

    private let bundleURL: URL
    private let schema: BundleSchema
    private let sessionID = UUID().uuidString
    private var startedSession = false

    init(bundleURL: URL, schema: BundleSchema) {
        self.bundleURL = bundleURL
        self.schema = schema
    }

    func send(_ prompt: String) {
        send(prompt, display: prompt)
    }

    /// Sends `prompt` to the agent but shows `display` in the transcript. Used when the
    /// literal prompt would be noise (e.g. the auto-diagnosis dumps the full issue list).
    func send(_ prompt: String, display: String) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, !isRunning else { return }
        let shown = display.trimmingCharacters(in: .whitespacesAndNewlines)
        messages.append(Message(role: .user, text: shown.isEmpty ? trimmedPrompt : shown))
        isRunning = true
        let resuming = startedSession
        startedSession = true
        Task { await run(prompt: trimmedPrompt, resuming: resuming) }
    }

    private func run(prompt: String, resuming: Bool) async {
        guard let claude = Self.claudeExecutableURL() else {
            finish(error: "Could not find the `claude` CLI. Install Claude Code, or set "
                + "DECKLOG_CLAUDE_BIN to its full path.")
            return
        }

        // The prompt is NOT passed as an argument: text starting with "-" would be parsed
        // as a CLI option. Instead it's written to stdin, which `claude -p` reads as the
        // prompt when no positional prompt is given.
        var args = [
            "-p",
            "--output-format", "stream-json", "--verbose",
            "--permission-mode", "acceptEdits",
            "--disallowedTools", "Bash",
            "--append-system-prompt", PMCharter.text(for: schema),
        ]
        args += resuming ? ["--resume", sessionID] : ["--session-id", sessionID]

        let process = Process()
        process.executableURL = claude
        process.arguments = args
        process.currentDirectoryURL = bundleURL
        process.environment = Self.childEnvironment()

        let inPipe = Pipe()
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardInput = inPipe
        process.standardOutput = outPipe
        process.standardError = errPipe

        do {
            try process.run()
        } catch {
            finish(error: "Failed to launch claude: \(error.localizedDescription)")
            return
        }

        // Feed the prompt via stdin, then close it so claude knows input is complete.
        inPipe.fileHandleForWriting.write(Data(prompt.utf8))
        inPipe.fileHandleForWriting.closeFile()

        var assistantIndex: Int?
        do {
            for try await line in outPipe.fileHandleForReading.bytes.lines {
                ingest(line: line, assistantIndex: &assistantIndex)
            }
        } catch {
            // Stream ended abnormally; the exit status below reports the failure.
        }

        process.waitUntilExit() // returns promptly: stdout already reached EOF

        if process.terminationStatus != 0 {
            let stderr = String(
                decoding: errPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self
            ).trimmingCharacters(in: .whitespacesAndNewlines)
            messages.append(Message(
                role: .error,
                text: stderr.isEmpty ? "claude exited with status \(process.terminationStatus)" : stderr
            ))
        }

        finish(commitMessage: Self.commitMessage(for: prompt))
    }

    // MARK: Stream parsing

    private func ingest(line: String, assistantIndex: inout Int?) {
        guard let data = line.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = obj["type"] as? String else { return }

        switch type {
        case "assistant":
            guard let message = obj["message"] as? [String: Any],
                  let content = message["content"] as? [[String: Any]] else { return }
            for item in content {
                switch item["type"] as? String {
                case "text":
                    if let text = item["text"] as? String {
                        appendAssistantText(text, index: &assistantIndex)
                    }
                case "tool_use":
                    let name = item["name"] as? String ?? "tool"
                    let input = item["input"] as? [String: Any]
                    messages.append(Message(role: .activity, text: Self.activityLabel(name: name, input: input)))
                    assistantIndex = nil // any following text starts a fresh bubble
                default:
                    break
                }
            }
        case "result":
            // Fallback: if no assistant text streamed, show the terminal result string.
            if assistantIndex == nil, let result = obj["result"] as? String, !result.isEmpty {
                messages.append(Message(role: .assistant, text: result))
            }
        default:
            break
        }
    }

    private func appendAssistantText(_ text: String, index: inout Int?) {
        if let i = index {
            messages[i].text += text
        } else {
            messages.append(Message(role: .assistant, text: text))
            index = messages.count - 1
        }
    }

    // MARK: Completion

    private func finish(commitMessage: String) {
        isRunning = false
        onTurnComplete?(commitMessage)
    }

    private func finish(error: String) {
        messages.append(Message(role: .error, text: error))
        isRunning = false
    }

    // MARK: Helpers

    private static func activityLabel(name: String, input: [String: Any]?) -> String {
        if let path = input?["file_path"] as? String {
            return "\(name) \((path as NSString).lastPathComponent)"
        }
        return name
    }

    private static func commitMessage(for prompt: String) -> String {
        let firstLine = prompt.split(separator: "\n").first.map(String.init) ?? prompt
        let clipped = firstLine.count > 60 ? String(firstLine.prefix(60)) + "…" : firstLine
        return "pm: \(clipped)"
    }

    /// A GUI process inherits a minimal PATH; add the usual Claude Code install dirs.
    private static func childEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        let extra = ["/opt/homebrew/bin", "/usr/local/bin", "\(NSHomeDirectory())/.claude/local"]
        env["PATH"] = ([env["PATH"]].compactMap { $0 } + extra).joined(separator: ":")
        return env
    }

    private static func claudeExecutableURL() -> URL? {
        let fm = FileManager.default
        if let override = ProcessInfo.processInfo.environment["DECKLOG_CLAUDE_BIN"],
           fm.isExecutableFile(atPath: override) {
            return URL(fileURLWithPath: override)
        }
        let home = NSHomeDirectory()
        let candidates = [
            "/opt/homebrew/bin/claude",
            "/usr/local/bin/claude",
            "\(home)/.claude/local/claude",
            "\(home)/.local/bin/claude",
            "/usr/bin/claude",
        ]
        return candidates.first(where: fm.isExecutableFile(atPath:)).map { URL(fileURLWithPath: $0) }
    }
}
