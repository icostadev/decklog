import XCTest
@testable import OKFKit

final class BundleTests: XCTestCase {

    func testLoadsSampleBundle() throws {
        // Robust against the sample bundle growing as demo data: assert the version, the
        // presence of each kind, and that every task carries a recognized status — not
        // exact totals.
        let bundle = try OKFBundle.load(at: sampleBundleURL())

        XCTAssertEqual(bundle.okfVersion, "0.1")
        XCTAssertNotNil(bundle.concept("projects/checkout-revamp/project"))

        XCTAssertFalse(bundle.concepts(ofKind: .task).isEmpty)
        XCTAssertFalse(bundle.concepts(ofKind: .project).isEmpty)
        XCTAssertFalse(bundle.concepts(ofKind: .milestone).isEmpty)
        XCTAssertFalse(bundle.concepts(ofKind: .knowledge).isEmpty)

        let validTaskStatuses = Set(TaskStatus.allCases.map(\.rawValue))
        for task in bundle.concepts(ofKind: .task) {
            if let status = task.status {
                XCTAssertTrue(validTaskStatuses.contains(status), "\(task.id): unexpected status `\(status)`")
            }
        }
    }

    func testConceptIDsAreRelativePathsMinusExtension() throws {
        let bundle = try OKFBundle.load(at: sampleBundleURL())
        let apple = bundle.concept("projects/checkout-revamp/tasks/apple-pay")
        XCTAssertNotNil(apple)
        XCTAssertEqual(apple?.assignee, "agents/backend-impl")
        XCTAssertEqual(apple?.parent, "projects/checkout-revamp/milestones/beta")
    }

    func testReservedFilesAreNotConcepts() throws {
        let bundle = try OKFBundle.load(at: sampleBundleURL())
        XCTAssertNil(bundle.concept("index"))
        XCTAssertNil(bundle.concept("log"))
        XCTAssertNil(bundle.concept("projects/checkout-revamp/index"))
    }

    func testTolerantLoadQuarantinesBadFileAndKeepsGoodOnes() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("okfkit-tolerant-\(UUID().uuidString)")
        try FileManager.default.createDirectory(
            at: dir.appendingPathComponent("tasks"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        try "---\ntype: task\ntitle: Good\n---\nok"
            .write(to: dir.appendingPathComponent("tasks/good.md"), atomically: true, encoding: .utf8)
        // Unquoted value with an inner `: ` — invalid YAML (mapping values not allowed).
        try "---\ntype: task\ndescription: a: b\n---\nx"
            .write(to: dir.appendingPathComponent("tasks/bad.md"), atomically: true, encoding: .utf8)

        let bundle = try OKFBundle.load(at: dir) // must NOT throw
        XCTAssertNotNil(bundle.concept("tasks/good"))
        XCTAssertNil(bundle.concept("tasks/bad"))
        XCTAssertEqual(bundle.loadErrors.map(\.path), ["tasks/bad.md"])
        XCTAssertFalse(bundle.loadErrors.first?.message.isEmpty ?? true)
    }

    func testAbsentSchemaUsesDefault() throws {
        // The sample bundle has no decklog.yaml → built-in vocabulary.
        let bundle = try OKFBundle.load(at: sampleBundleURL())
        XCTAssertEqual(bundle.schema, .default)
    }

    func testLoadsCustomSchemaFromDecklogYaml() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("okfkit-schema-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        try "task_statuses: [backlog, doing, done]"
            .write(to: dir.appendingPathComponent("decklog.yaml"), atomically: true, encoding: .utf8)

        let bundle = try OKFBundle.load(at: dir)
        XCTAssertEqual(bundle.schema.taskStatuses.map(\.id), ["backlog", "doing", "done"])
        XCTAssertTrue(bundle.loadErrors.isEmpty)
    }

    func testMalformedSchemaFallsBackAndReports() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("okfkit-schema-bad-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        // A scalar where a list is required — must not fail the open.
        try "task_statuses: oops"
            .write(to: dir.appendingPathComponent("decklog.yaml"), atomically: true, encoding: .utf8)

        let bundle = try OKFBundle.load(at: dir)          // must NOT throw
        XCTAssertEqual(bundle.schema, .default)            // fell back
        XCTAssertTrue(bundle.loadErrors.contains { $0.path == "decklog.yaml" })
    }

    func testDerivedBlocksIsInverseOfBlockedBy() throws {
        let bundle = try OKFBundle.load(at: sampleBundleURL())
        XCTAssertEqual(
            bundle.blocks(of: "projects/checkout-revamp/tasks/pci-review"),
            ["projects/checkout-revamp/tasks/apple-pay"]
        )
        XCTAssertEqual(bundle.blocks(of: "projects/checkout-revamp/tasks/apple-pay"), [])
    }
}
