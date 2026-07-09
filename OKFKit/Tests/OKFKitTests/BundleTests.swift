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

    func testDerivedBlocksIsInverseOfBlockedBy() throws {
        let bundle = try OKFBundle.load(at: sampleBundleURL())
        XCTAssertEqual(
            bundle.blocks(of: "projects/checkout-revamp/tasks/pci-review"),
            ["projects/checkout-revamp/tasks/apple-pay"]
        )
        XCTAssertEqual(bundle.blocks(of: "projects/checkout-revamp/tasks/apple-pay"), [])
    }
}
