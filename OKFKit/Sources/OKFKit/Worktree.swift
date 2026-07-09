import Foundation

/// A git worktree an executor runs in — an isolated checkout on its own branch, so a
/// background run never touches the user's working tree (DESIGN §9).
public struct Worktree: Equatable {
    public let path: URL
    public let branch: String
}

public enum WorktreeManager {
    /// `git worktree add -b <branch> <path> <base>` in `repo`.
    @discardableResult
    public static func create(
        inRepo repo: URL, branch: String, base: String = "HEAD", at path: URL
    ) throws -> Worktree {
        try BundleGit.run(["worktree", "add", "-b", branch, path.path, base], in: repo)
        return Worktree(path: path, branch: branch)
    }

    public static func remove(_ worktree: Worktree, inRepo repo: URL, force: Bool = true) throws {
        var args = ["worktree", "remove"]
        if force { args.append("--force") }
        args.append(worktree.path.path)
        try BundleGit.run(args, in: repo)
    }

    /// Paths of all worktrees registered in `repo` (including the main one).
    public static func list(inRepo repo: URL) throws -> [URL] {
        let output = try BundleGit.run(["worktree", "list", "--porcelain"], in: repo)
        return output.split(separator: "\n").compactMap { line in
            guard line.hasPrefix("worktree ") else { return nil }
            return URL(fileURLWithPath: String(line.dropFirst("worktree ".count)))
        }
    }
}
