import XCTest
@testable import OKFKit

final class BundleTests: XCTestCase {

    func testLoadsSampleBundle() throws {
        let bundle = try OKFBundle.load(at: sampleBundleURL())

        // Reserved files (index.md, log.md) are excluded; 11 concepts remain.
        XCTAssertEqual(bundle.allConcepts.count, 11)
        XCTAssertEqual(bundle.okfVersion, "0.1")

        XCTAssertEqual(bundle.concepts(ofKind: .task).count, 3)
        XCTAssertEqual(bundle.concepts(ofKind: .project).count, 1)
        XCTAssertEqual(bundle.concepts(ofKind: .milestone).count, 1)
        XCTAssertEqual(bundle.concepts(ofKind: .objective).count, 1)
        XCTAssertEqual(bundle.concepts(ofKind: .agent).count, 2)
        XCTAssertEqual(bundle.concepts(ofKind: .knowledge).count, 2)
        XCTAssertEqual(bundle.concepts(ofKind: .cycle).count, 1)
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
