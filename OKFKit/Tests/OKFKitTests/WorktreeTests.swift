import XCTest
@testable import OKFKit

final class WorktreeTests: XCTestCase {

    private var repo: URL!
    private var worktreePath: URL!

    override func setUpWithError() throws {
        let tmp = FileManager.default.temporaryDirectory
        repo = tmp.appendingPathComponent("okfkit-repo-\(UUID().uuidString)")
        worktreePath = tmp.appendingPathComponent("okfkit-wt-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: repo, withIntermediateDirectories: true)
        try BundleGit.initialize(at: repo)
        try "hello".write(to: repo.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try BundleGit.commitAll(at: repo, message: "init") // worktree add needs a HEAD
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: repo)
        try? FileManager.default.removeItem(at: worktreePath)
    }

    func testCreateListRemoveWorktree() throws {
        let wt = try WorktreeManager.create(inRepo: repo, branch: "decklog/t1", at: worktreePath)

        // The worktree is a real checkout of the repo.
        XCTAssertTrue(FileManager.default.fileExists(
            atPath: wt.path.appendingPathComponent("README.md").path))

        // The branch was created.
        let branches = try BundleGit.run(["branch", "--list", "decklog/t1"], in: repo)
        XCTAssertTrue(branches.contains("decklog/t1"))

        // It's registered as a worktree.
        let listed = try WorktreeManager.list(inRepo: repo).map { $0.standardizedFileURL.path }
        XCTAssertTrue(listed.contains(worktreePath.standardizedFileURL.path))

        // Removing it deletes the checkout.
        try WorktreeManager.remove(wt, inRepo: repo)
        XCTAssertFalse(FileManager.default.fileExists(atPath: worktreePath.path))
    }

    func testPruneDropsStaleWorktree() throws {
        let wt = try WorktreeManager.create(inRepo: repo, branch: "decklog/t2", at: worktreePath)
        // Simulate a stale worktree: delete its directory out from under git.
        try FileManager.default.removeItem(at: wt.path)
        XCTAssertTrue(try WorktreeManager.list(inRepo: repo)
            .map { $0.standardizedFileURL.path }.contains(worktreePath.standardizedFileURL.path))

        try WorktreeManager.prune(inRepo: repo)
        XCTAssertFalse(try WorktreeManager.list(inRepo: repo)
            .map { $0.standardizedFileURL.path }.contains(worktreePath.standardizedFileURL.path))
    }
}
