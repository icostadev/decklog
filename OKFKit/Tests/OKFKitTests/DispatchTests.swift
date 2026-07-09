import XCTest
@testable import OKFKit

final class DispatchTests: XCTestCase {

    private func bundle() throws -> OKFBundle { try OKFBundle.load(at: sampleBundleURL()) }

    func testGateAllowsReadyAndUnblocked() throws {
        // tax-rate-config: ready, no blockers.
        let d = try bundle().dispatchDecision(forTask: "projects/financial-assets/tasks/tax-rate-config")
        XCTAssertTrue(d.canDispatch, "reasons: \(d.reasons)")
        XCTAssertTrue(d.reasons.isEmpty)
    }

    func testGateBlocksNonReadyTask() throws {
        // apple-pay: in_progress.
        let d = try bundle().dispatchDecision(forTask: "projects/checkout-revamp/tasks/apple-pay")
        XCTAssertFalse(d.canDispatch)
        XCTAssertTrue(d.reasons.contains { $0.contains("not `ready`") })
    }

    func testGateBlocksReadyTaskWithOpenBlockers() throws {
        // net-worth-view: ready, but its blockers aren't done.
        let d = try bundle().dispatchDecision(forTask: "projects/financial-assets/tasks/net-worth-view")
        XCTAssertFalse(d.canDispatch)
        XCTAssertTrue(d.reasons.contains { $0.contains("blocked by") })
    }

    func testGateRejectsNonTask() throws {
        let d = try bundle().dispatchDecision(forTask: "projects/checkout-revamp/project")
        XCTAssertFalse(d.canDispatch)
    }

    func testBranchName() {
        XCTAssertEqual(
            ExecutorBranch.name(forTask: "projects/x/tasks/apple-pay"),
            "decklog/projects-x-tasks-apple-pay"
        )
    }
}
