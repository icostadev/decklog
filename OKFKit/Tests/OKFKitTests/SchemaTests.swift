import XCTest
@testable import OKFKit

final class SchemaTests: XCTestCase {

    // MARK: .default reproduces the built-in enums

    func testDefaultTaskStatusesMatchEnum() {
        XCTAssertEqual(
            BundleSchema.default.taskStatuses.map(\.id),
            TaskStatus.allCases.map(\.rawValue)
        )
    }

    func testDefaultMilestoneStatusesMatchEnum() {
        XCTAssertEqual(
            BundleSchema.default.milestoneStatuses.map(\.id),
            WorkStatus.allCases.map(\.rawValue)
        )
    }

    func testDefaultObjectiveStatusesMatchEnum() {
        XCTAssertEqual(
            BundleSchema.default.objectiveStatuses.map(\.id),
            ObjectiveStatus.allCases.map(\.rawValue)
        )
    }

    // MARK: allowedStatuses(for:) mirrors the former StatusVocabulary

    func testAllowedStatusesByKind() {
        let s = BundleSchema.default
        XCTAssertEqual(s.allowedStatuses(for: .task), TaskStatus.allCases.map(\.rawValue))
        XCTAssertEqual(s.allowedStatuses(for: .project), WorkStatus.allCases.map(\.rawValue))
        XCTAssertEqual(s.allowedStatuses(for: .milestone), WorkStatus.allCases.map(\.rawValue))
        XCTAssertEqual(s.allowedStatuses(for: .objective), ObjectiveStatus.allCases.map(\.rawValue))
        XCTAssertNil(s.allowedStatuses(for: .agent))
        XCTAssertNil(s.allowedStatuses(for: .knowledge))
    }

    // MARK: role lookups

    func testTaskStatusForRole() {
        let s = BundleSchema.default
        XCTAssertEqual(s.taskStatus(for: .ready), "ready")
        XCTAssertEqual(s.taskStatus(for: .inProgress), "in_progress")
        XCTAssertEqual(s.taskStatus(for: .inReview), "in_review")
        XCTAssertEqual(s.taskStatus(for: .done), "done")
        XCTAssertEqual(s.taskStatus(for: .cancelled), "cancelled")
    }

    // MARK: board columns + labels

    func testTaskColumnsExcludeOffBoardStatuses() {
        // `cancelled` is off-board, so it isn't a column; the rest are, in order.
        XCTAssertEqual(
            BundleSchema.default.taskColumns.map(\.id),
            ["draft", "ready", "in_progress", "in_review", "done"]
        )
    }

    func testTaskLabelDerivation() {
        let s = BundleSchema.default
        XCTAssertEqual(s.taskLabel("in_progress"), "In progress")
        XCTAssertEqual(s.taskLabel("in_review"), "In review")
        XCTAssertEqual(s.taskLabel("draft"), "Draft")
        XCTAssertEqual(s.taskLabel("done"), "Done")
        // Unknown id still gets a sensible derived label.
        XCTAssertEqual(s.taskLabel("in_qa"), "In qa")
    }

    func testStatusDefDefaultLabel() {
        XCTAssertEqual(StatusDef.defaultLabel(for: "in_progress"), "In progress")
        XCTAssertEqual(StatusDef.defaultLabel(for: "code-review"), "Code review")
        XCTAssertEqual(StatusDef.defaultLabel(for: "ready"), "Ready")
    }

    func testExplicitLabelOverridesDerived() {
        XCTAssertEqual(StatusDef(id: "wip", label: "Work in progress").label, "Work in progress")
        XCTAssertEqual(StatusDef(id: "wip").label, "Wip")
    }
}
