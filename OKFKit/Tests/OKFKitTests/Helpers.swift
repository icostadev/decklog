import Foundation
import XCTest
@testable import OKFKit

/// Locates the hand-authored sample bundle at `<repo>/sample-bundle`.
/// This test file lives at `OKFKit/Tests/OKFKitTests/`, so three parents up is the
/// `OKFKit/` package dir; `../sample-bundle` is the repo-level bundle.
func sampleBundleURL(file: StaticString = #file) -> URL {
    URL(fileURLWithPath: "\(file)")
        .deletingLastPathComponent() // OKFKitTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // OKFKit
        .appendingPathComponent("../sample-bundle")
        .standardizedFileURL
}

func makeConcept(_ id: String, _ yaml: String, body: String = "") throws -> Concept {
    try Concept.parse(id: id, raw: "---\n\(yaml)\n---\n\(body)")
}
