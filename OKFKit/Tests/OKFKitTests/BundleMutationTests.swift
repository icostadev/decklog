import XCTest
@testable import OKFKit

final class BundleMutationTests: XCTestCase {

    func testSetStatusRoundTripsAndPreservesUnknownKeys() throws {
        var c = try Concept.parse(
            id: "t/1",
            raw: "---\ntype: task\ntitle: X\nstatus: ready\ncustom: keep\n---\nbody"
        )
        c.set(status: "in_review")
        let reparsed = try Concept.parse(id: "t/1", raw: try c.serialized())
        XCTAssertEqual(reparsed.status, "in_review")
        XCTAssertEqual(reparsed.type, "task")
        XCTAssertEqual(reparsed.frontmatter.string("custom"), "keep")
    }

    func testSetArtifactsRoundTrips() throws {
        var c = try Concept.parse(id: "t/1", raw: "---\ntype: task\n---\n")
        c.set(artifacts: ["https://x/pull/1", "decklog/t-1"])
        let reparsed = try Concept.parse(id: "t/1", raw: try c.serialized())
        XCTAssertEqual(reparsed.artifacts, ["https://x/pull/1", "decklog/t-1"])
    }

    func testRepoURLResolvesRelativeAbsoluteAndRemote() throws {
        let root = URL(fileURLWithPath: "/tmp/bundleroot")

        let relative = try Concept.parse(id: "projects/x/project", raw: "---\ntype: project\nrepo: \"..\"\n---\n")
        let b1 = OKFBundle(rootURL: root, concepts: ["projects/x/project": relative])
        XCTAssertEqual(b1.repoURL(forProject: "projects/x/project")?.standardizedFileURL.path, "/tmp")

        let absolute = try Concept.parse(id: "projects/y/project", raw: "---\ntype: project\nrepo: /abs/repo\n---\n")
        let b2 = OKFBundle(rootURL: root, concepts: ["projects/y/project": absolute])
        XCTAssertEqual(b2.repoURL(forProject: "projects/y/project")?.path, "/abs/repo")

        let remote = try Concept.parse(id: "projects/z/project", raw: "---\ntype: project\nrepo: \"git@github.com:a/b.git\"\n---\n")
        let b3 = OKFBundle(rootURL: root, concepts: ["projects/z/project": remote])
        XCTAssertNil(b3.repoURL(forProject: "projects/z/project"))
    }

    func testProjectForTask() throws {
        let bundle = try OKFBundle.load(at: sampleBundleURL())
        XCTAssertEqual(
            bundle.project(forTask: "projects/checkout-revamp/tasks/apple-pay")?.id,
            "projects/checkout-revamp/project"
        )
    }

    func testWritePersistsToDisk() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("okfkit-write-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: dir.appendingPathComponent("t"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        var c = try Concept.parse(id: "t/1", raw: "---\ntype: task\nstatus: ready\n---\nhi")
        let bundle = OKFBundle(rootURL: dir, concepts: ["t/1": c])
        c.set(status: "done")
        try bundle.write(c)

        let reloaded = try OKFBundle.load(at: dir)
        XCTAssertEqual(reloaded.concept("t/1")?.status, "done")
    }
}
