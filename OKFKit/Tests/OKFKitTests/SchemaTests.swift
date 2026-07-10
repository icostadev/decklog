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

    // MARK: parse(yaml:)

    func testParseEmptyReturnsDefault() throws {
        XCTAssertEqual(try BundleSchema.parse(yaml: ""), .default)
        XCTAssertEqual(try BundleSchema.parse(yaml: "   \n  "), .default)
    }

    func testParseMissingSectionsFallBackToDefault() throws {
        let s = try BundleSchema.parse(yaml: "task_statuses: [backlog, done]")
        XCTAssertEqual(s.taskStatuses.map(\.id), ["backlog", "done"])
        // Untouched sections keep the built-in default.
        XCTAssertEqual(s.milestoneStatuses, BundleSchema.default.milestoneStatuses)
        XCTAssertEqual(s.objectiveStatuses, BundleSchema.default.objectiveStatuses)
    }

    func testParseShorthandAutoBindsRoleAndOffBoardsCancelled() throws {
        let s = try BundleSchema.parse(yaml: "task_statuses: [backlog, ready, done, cancelled]")
        XCTAssertNil(s.taskStatuses[0].role)                 // backlog: no built-in role
        XCTAssertEqual(s.taskStatus(for: .ready), "ready")   // auto-bound from id
        XCTAssertEqual(s.taskStatus(for: .done), "done")
        XCTAssertEqual(s.taskStatus(for: .cancelled), "cancelled")
        // cancelled auto-off-board; the rest are columns.
        XCTAssertEqual(s.taskColumns.map(\.id), ["backlog", "ready", "done"])
    }

    func testParseFullFormWithRenamedRoleAndLabel() throws {
        let yaml = """
        task_statuses:
          - { id: backlog, label: Backlog }
          - { id: doing, label: Doing, role: in_progress }
          - { id: shipped, role: done }
          - { id: dropped, column: false, role: cancelled }
        """
        let s = try BundleSchema.parse(yaml: yaml)
        XCTAssertEqual(s.taskStatuses.map(\.id), ["backlog", "doing", "shipped", "dropped"])
        XCTAssertEqual(s.taskLabel("doing"), "Doing")
        XCTAssertEqual(s.taskStatus(for: .inProgress), "doing")   // renamed but role-mapped
        XCTAssertEqual(s.taskStatus(for: .done), "shipped")
        XCTAssertEqual(s.taskColumns.map(\.id), ["backlog", "doing", "shipped"]) // dropped off-board
    }

    func testParseColumnOverrideKeepsCancelledVisible() throws {
        let s = try BundleSchema.parse(yaml: "task_statuses: [{ id: cancelled, column: true, role: cancelled }]")
        XCTAssertEqual(s.taskColumns.map(\.id), ["cancelled"])
    }

    func testParseNotAListThrows() {
        XCTAssertThrowsError(try BundleSchema.parse(yaml: "task_statuses: nope")) { error in
            guard let e = error as? SchemaError, case .notAList = e else {
                return XCTFail("got \(error)")
            }
        }
    }

    func testParseMissingIDThrows() {
        XCTAssertThrowsError(try BundleSchema.parse(yaml: "task_statuses: [{ label: X }]")) { error in
            guard let e = error as? SchemaError, case .missingID = e else {
                return XCTFail("got \(error)")
            }
        }
    }

    func testParseUnknownRoleThrows() {
        XCTAssertThrowsError(try BundleSchema.parse(yaml: "task_statuses: [{ id: foo, role: bogus }]")) { error in
            guard let e = error as? SchemaError, case .unknownRole = e else {
                return XCTFail("got \(error)")
            }
        }
    }
}
