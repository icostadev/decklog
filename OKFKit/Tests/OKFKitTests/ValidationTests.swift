import XCTest
@testable import OKFKit

final class ValidationTests: XCTestCase {

    func testSampleBundleIsClean() throws {
        let bundle = try OKFBundle.load(at: sampleBundleURL())
        let issues = bundle.validate()
        XCTAssertTrue(issues.isEmpty, "expected a clean bundle, got: \(issues)")
    }

    func testDetectsDanglingReference() throws {
        let task = try makeConcept("t/1", """
        type: task
        status: ready
        parent: t/does-not-exist
        """)
        let bundle = OKFBundle.inMemory([task])
        let issues = bundle.validate()
        XCTAssertTrue(issues.contains {
            $0.conceptID == "t/1" && $0.message.contains("parent") && $0.severity == .warning
        })
    }

    func testDetectsBlockedByCycle() throws {
        let a = try makeConcept("t/a", "type: task\nstatus: ready\nblocked_by: [t/b]")
        let b = try makeConcept("t/b", "type: task\nstatus: ready\nblocked_by: [t/a]")
        let bundle = OKFBundle.inMemory([a, b])
        let issues = bundle.validate()
        XCTAssertTrue(issues.contains {
            $0.severity == .error && $0.message.contains("blocked_by cycle")
        })
    }

    func testFlagsUnknownStatusForType() throws {
        let task = try makeConcept("t/1", "type: task\nstatus: frozen")
        let issues = OKFBundle.inMemory([task]).validate()
        XCTAssertTrue(issues.contains {
            $0.message.contains("unknown status `frozen`")
        })
    }

    func testFlagsStartAfterDue() throws {
        let task = try makeConcept("t/1", """
        type: task
        status: ready
        start: 2026-07-20
        due: 2026-07-10
        """)
        let issues = OKFBundle.inMemory([task]).validate()
        XCTAssertTrue(issues.contains { $0.message.contains("start") && $0.message.contains("after due") })
    }

    func testValidStatusPasses() throws {
        let task = try makeConcept("t/1", "type: task\nstatus: in_progress")
        let issues = OKFBundle.inMemory([task]).validate()
        XCTAssertFalse(issues.contains { $0.message.contains("unknown status") })
    }
}
