import Foundation

public enum GitError: Error, CustomStringConvertible {
    case commandFailed(command: String, status: Int32, stderr: String)

    public var description: String {
        switch self {
        case let .commandFailed(command, status, stderr):
            return "git \(command) failed (\(status)): \(stderr)"
        }
    }
}

/// Minimal git operations over a bundle directory, via the `git` CLI. Used to version
/// the bundle after the PM agent edits it (DESIGN.md §9: git is the event log).
///
/// Commits set an explicit identity with `-c` so they succeed even when the repo/user
/// has no configured `user.name`/`user.email`.
public enum BundleGit {
    public static let committerName = "Decklog"
    public static let committerEmail = "decklog@localhost"

    @discardableResult
    static func run(_ args: [String], in directory: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + args
        process.currentDirectoryURL = directory

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            throw GitError.commandFailed(
                command: args.joined(separator: " "),
                status: process.terminationStatus,
                stderr: String(decoding: errData, as: UTF8.self)
            )
        }
        return String(decoding: outData, as: UTF8.self)
    }

    public static func isRepository(at url: URL) -> Bool {
        (try? run(["rev-parse", "--is-inside-work-tree"], in: url)) != nil
    }

    /// True only when `url` is the top level of the git work tree — not merely inside a
    /// larger repo. Guards against committing bundle edits into an unrelated parent repo.
    public static func isRepositoryRoot(at url: URL) -> Bool {
        guard let top = try? run(["rev-parse", "--show-toplevel"], in: url) else { return false }
        let topPath = URL(fileURLWithPath: top.trimmingCharacters(in: .whitespacesAndNewlines))
            .standardizedFileURL.path
        return topPath == url.standardizedFileURL.path
    }

    public static func initialize(at url: URL) throws {
        try run(["init"], in: url)
    }

    public static func hasChanges(at url: URL) throws -> Bool {
        let status = try run(["status", "--porcelain", "--", "."], in: url)
        return !status.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Stage everything under the bundle dir and commit. Returns `false` if nothing to commit.
    @discardableResult
    public static func commitAll(at url: URL, message: String) throws -> Bool {
        guard try hasChanges(at: url) else { return false }
        try run(["add", "-A", "--", "."], in: url)
        try run([
            "-c", "user.name=\(committerName)",
            "-c", "user.email=\(committerEmail)",
            "commit", "-m", message,
        ], in: url)
        return true
    }
}
