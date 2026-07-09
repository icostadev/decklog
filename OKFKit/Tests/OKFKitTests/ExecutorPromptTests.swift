import XCTest
@testable import OKFKit

final class ExecutorPromptTests: XCTestCase {

    private func applePay() throws -> (Concept, OKFBundle) {
        let bundle = try OKFBundle.load(at: sampleBundleURL())
        let task = try XCTUnwrap(bundle.concept("projects/checkout-revamp/tasks/apple-pay"))
        return (task, bundle)
    }

    func testResolvesContextConceptLinks() throws {
        let (task, bundle) = try applePay()
        let ids = ExecutorPrompt.contextConceptIDs(forTask: task, in: bundle)
        XCTAssertTrue(ids.contains("knowledge/checkout-flow"))
        XCTAssertTrue(ids.contains("knowledge/decisions/apple-pay-over-stripe-link"))
    }

    func testPromptIncludesSpecAndResolvedContext() throws {
        let (task, bundle) = try applePay()
        let prompt = ExecutorPrompt.build(forTask: task, in: bundle)

        XCTAssertTrue(prompt.hasPrefix("# Task: Add Apple Pay to checkout"))
        XCTAssertTrue(prompt.contains("## Acceptance criteria"))
        XCTAssertTrue(prompt.contains("Apple Pay button appears"))
        // The linked knowledge concept's body is inlined.
        XCTAssertTrue(prompt.contains("The checkout has three steps"))
    }

    func testNoContextSectionYieldsNoRefs() throws {
        let task = try Concept.parse(id: "t/1", raw: "---\ntype: task\n---\nJust a body, no context.")
        let bundle = OKFBundle.inMemory([task])
        XCTAssertTrue(ExecutorPrompt.contextConceptIDs(forTask: task, in: bundle).isEmpty)
    }
}
