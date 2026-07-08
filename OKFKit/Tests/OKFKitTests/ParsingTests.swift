import XCTest
@testable import OKFKit

final class ParsingTests: XCTestCase {

    func testParsesFrontmatterAndBody() throws {
        let raw = """
        ---
        type: task
        title: "Add Apple Pay"
        status: in_progress
        blocked_by: [a/b, c/d]
        priority: p1
        ---

        Body line one.

        ## Acceptance criteria
        - [ ] works
        """
        let c = try Concept.parse(id: "projects/x/tasks/apple-pay", raw: raw)

        XCTAssertEqual(c.type, "task")
        XCTAssertEqual(c.kind, .task)
        XCTAssertEqual(c.title, "Add Apple Pay")
        XCTAssertEqual(c.status, "in_progress")
        XCTAssertEqual(c.priority, "p1")
        XCTAssertEqual(c.blockedBy, ["a/b", "c/d"])
        XCTAssertTrue(c.body.contains("## Acceptance criteria"))
        XCTAssertTrue(c.body.hasPrefix("Body line one."))
    }

    func testTitleFallsBackToID() throws {
        let c = try makeConcept("knowledge/foo", "type: knowledge")
        XCTAssertEqual(c.title, "knowledge/foo")
    }

    func testNoFrontmatterIsTolerated() throws {
        let c = try Concept.parse(id: "notes/plain", raw: "# Just prose\n\nno frontmatter")
        XCTAssertEqual(c.type, "")
        XCTAssertEqual(c.kind, .other(""))
        XCTAssertTrue(c.body.contains("Just prose"))
    }

    func testUnknownTypeMapsToOther() throws {
        let c = try makeConcept("x/y", "type: bigquery-table")
        XCTAssertEqual(c.kind, .other("bigquery-table"))
    }

    func testRoundTripPreservesUnknownKeysOrderAndBody() throws {
        let raw = """
        ---
        type: task
        title: My task
        status: ready
        custom_key: keep-me
        nested:
          a: 1
          b: two
        list_field:
          - one
          - two
        ---
        Hello world.

        ## Section
        Text.
        """
        let c1 = try Concept.parse(id: "t/1", raw: raw)
        let serialized = try c1.serialized()
        let c2 = try Concept.parse(id: "t/1", raw: serialized)

        // Unknown keys survive.
        XCTAssertEqual(c2.frontmatter.string("custom_key"), "keep-me")
        XCTAssertNotNil(c2.frontmatter["nested"])
        XCTAssertNotNil(c2.frontmatter["list_field"])

        // Key order is preserved.
        XCTAssertEqual(
            c2.frontmatter.keys,
            ["type", "title", "status", "custom_key", "nested", "list_field"]
        )

        // Known fields survive.
        XCTAssertEqual(c2.type, "task")
        XCTAssertEqual(c2.title, "My task")
        XCTAssertEqual(c2.status, "ready")

        // Body is stable across the round-trip.
        XCTAssertEqual(c1.body, c2.body)
        XCTAssertTrue(c2.body.contains("## Section"))
    }
}
