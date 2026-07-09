import Foundation
import Combine
import OKFKit

/// One dispatched task run: create a git worktree, run headless Claude Code in it,
/// stream output, then commit the branch. Advances the task's lifecycle via callbacks
/// (the host writes those changes into the bundle). macOS-only runtime.
@MainActor
final class ExecutorSession: ObservableObject {

    enum Phase: String { case preparing, running, committing, review, failed }

    struct LogLine: Identifiable {
        enum Kind { case output, activity, system, error }
        let id = UUID()
        let kind: Kind
        let text: String
    }

    @Published private(set) var phase: Phase = .preparing
    @Published private(set) var log: [LogLine] = []
    @Published private(set) var branch: String?

    let taskID: String
    private let taskTitle: String
    private let prompt: String
    private let repoURL: URL

    /// Called with a new task status (`in_progress`, `in_review`) — the host persists it.
    var onStatusChange: ((String) -> Void)?
    /// Called with the produced branch name — the host records it in `artifacts`.
    var onArtifact: ((String) -> Void)?

    init(task: Concept, bundle: OKFBundle, repoURL: URL) {
        self.taskID = task.id
        self.taskTitle = task.title
        self.prompt = ExecutorPrompt.build(forTask: task, in: bundle)
        self.repoURL = repoURL
    }

    func start() {
        guard phase == .preparing else { return }
        Task { await run() }
    }

    private func run() async {
        let branchName = ExecutorBranch.name(forTask: taskID)
        let worktreePath = FileManager.default.temporaryDirectory
            .appendingPathComponent("decklog-worktrees")
            .appendingPathComponent("\(branchName.replacingOccurrences(of: "/", with: "-"))-\(UUID().uuidString.prefix(8))")

        // 1. Isolated worktree on the task's branch.
        let worktree: Worktree
        do {
            try FileManager.default.createDirectory(
                at: worktreePath.deletingLastPathComponent(), withIntermediateDirectories: true)
            worktree = try WorktreeManager.create(inRepo: repoURL, branch: branchName, at: worktreePath)
            append(.system, "Created worktree on `\(branchName)`")
        } catch {
            return fail("Could not create worktree: \(error.localizedDescription)")
        }

        // 2. Launch the executor.
        guard let claude = Self.claudeExecutableURL() else {
            try? WorktreeManager.remove(worktree, inRepo: repoURL)
            return fail("Could not find the `claude` CLI (set DECKLOG_CLAUDE_BIN).")
        }
        let process = Process()
        process.executableURL = claude
        process.arguments = [
            "-p",
            "--output-format", "stream-json", "--verbose",
            "--permission-mode", "acceptEdits",
            "--append-system-prompt", ExecutorCharter.text,
        ]
        process.currentDirectoryURL = worktree.path
        process.environment = Self.childEnvironment()

        let inPipe = Pipe(); let outPipe = Pipe(); let errPipe = Pipe()
        process.standardInput = inPipe
        process.standardOutput = outPipe
        process.standardError = errPipe
        do {
            try process.run()
        } catch {
            try? WorktreeManager.remove(worktree, inRepo: repoURL)
            return fail("Failed to launch claude: \(error.localizedDescription)")
        }

        // Now that the executor is running, mark the task in-progress.
        branch = branchName
        phase = .running
        onStatusChange?(TaskStatus.inProgress.rawValue)

        inPipe.fileHandleForWriting.write(Data(prompt.utf8))
        inPipe.fileHandleForWriting.closeFile()

        do {
            for try await line in outPipe.fileHandleForReading.bytes.lines { ingest(line) }
        } catch { /* stream ended; status checked below */ }
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let stderr = String(decoding: errPipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            append(.error, stderr.isEmpty ? "claude exited with status \(process.terminationStatus)" : stderr)
        }

        // 3. Commit whatever the executor produced onto its branch.
        phase = .committing
        do {
            let committed = try BundleGit.commitAll(at: worktree.path, message: "decklog: \(taskTitle)")
            append(.system, committed ? "Committed changes to `\(branchName)`" : "Executor made no changes")
        } catch {
            append(.error, "Commit failed: \(error.localizedDescription)")
        }

        // 3b. Remove the worktree — the branch preserves the work.
        do {
            try WorktreeManager.remove(worktree, inRepo: repoURL)
            append(.system, "Cleaned up worktree (branch `\(branchName)` kept)")
        } catch {
            append(.error, "Worktree cleanup failed: \(error.localizedDescription)")
            try? WorktreeManager.prune(inRepo: repoURL)
        }

        // 4. Hand off for human review.
        onArtifact?(branchName)
        onStatusChange?(TaskStatus.inReview.rawValue)
        phase = .review
    }

    // MARK: Stream parsing

    private func ingest(_ line: String) {
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
                    if let text = item["text"] as? String, !text.isEmpty { append(.output, text) }
                case "tool_use":
                    let name = item["name"] as? String ?? "tool"
                    let file = (item["input"] as? [String: Any])?["file_path"] as? String
                    append(.activity, file.map { "\(name) \(($0 as NSString).lastPathComponent)" } ?? name)
                default:
                    break
                }
            }
        default:
            break
        }
    }

    private func append(_ kind: LogLine.Kind, _ text: String) {
        log.append(LogLine(kind: kind, text: text))
    }

    private func fail(_ message: String) {
        append(.error, message)
        phase = .failed
    }

    // MARK: Claude CLI resolution (shared shape with PMAgentSession)

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
            "/opt/homebrew/bin/claude", "/usr/local/bin/claude",
            "\(home)/.claude/local/claude", "\(home)/.local/bin/claude", "/usr/bin/claude",
        ]
        return candidates.first(where: fm.isExecutableFile(atPath:)).map { URL(fileURLWithPath: $0) }
    }
}
