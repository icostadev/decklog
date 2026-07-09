import XCTest
@testable import OKFKit

final class GitTests: XCTestCase {

    private var tempDir: URL!

    override func setUpWithError() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("okfkit-git-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: tempDir)
    }

    private func write(_ name: String, _ contents: String) throws {
        try contents.write(
            to: tempDir.appendingPathComponent(name), atomically: true, encoding: .utf8
        )
    }

    func testIsRepositoryReflectsInit() throws {
        XCTAssertFalse(BundleGit.isRepository(at: tempDir))
        try BundleGit.initialize(at: tempDir)
        XCTAssertTrue(BundleGit.isRepository(at: tempDir))
    }

    func testIsRepositoryRootTrueOnlyAtTopLevel() throws {
        try BundleGit.initialize(at: tempDir)
        let sub = tempDir.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)

        XCTAssertTrue(BundleGit.isRepositoryRoot(at: tempDir))
        XCTAssertFalse(BundleGit.isRepositoryRoot(at: sub), "a subdir of a repo is not its root")
    }

    func testCommitAllCommitsChangesThenReportsNothingToCommit() throws {
        try BundleGit.initialize(at: tempDir)
        try write("a.md", "---\ntype: task\n---\nhi\n")

        XCTAssertTrue(try BundleGit.hasChanges(at: tempDir))
        XCTAssertTrue(try BundleGit.commitAll(at: tempDir, message: "add a"))

        // Nothing changed since the commit.
        XCTAssertFalse(try BundleGit.hasChanges(at: tempDir))
        XCTAssertFalse(try BundleGit.commitAll(at: tempDir, message: "noop"))
    }

    func testCommitSucceedsWithoutGlobalGitIdentity() throws {
        // The commit sets identity via -c, so it must work even with no user.* config.
        try BundleGit.initialize(at: tempDir)
        // Ensure no local identity is configured.
        _ = try? BundleGit.run(["config", "--unset", "user.name"], in: tempDir)
        _ = try? BundleGit.run(["config", "--unset", "user.email"], in: tempDir)

        try write("b.md", "---\ntype: task\n---\n")
        XCTAssertTrue(try BundleGit.commitAll(at: tempDir, message: "add b"))

        let log = try BundleGit.run(["log", "--format=%an <%ae>", "-1"], in: tempDir)
        XCTAssertTrue(log.contains("Decklog <decklog@localhost>"), "got: \(log)")
    }

    func testSecondCommitRecordsTwoCommits() throws {
        try BundleGit.initialize(at: tempDir)
        try write("a.md", "one")
        try BundleGit.commitAll(at: tempDir, message: "c1")
        try write("a.md", "two")
        try BundleGit.commitAll(at: tempDir, message: "c2")

        let count = try BundleGit.run(["rev-list", "--count", "HEAD"], in: tempDir)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        XCTAssertEqual(count, "2")
    }
}
