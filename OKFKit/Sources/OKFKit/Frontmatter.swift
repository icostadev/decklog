import Foundation
import Yams

/// A thin, order-preserving wrapper around a parsed YAML frontmatter mapping.
///
/// It keeps the underlying `Yams.Node` so that **unknown keys are preserved** on
/// round-trip (key insertion order is retained by Yams). Comments are *not*
/// preserved — that is a known limitation of the YAML round-trip in this iteration.
public struct Frontmatter {
    public var node: Yams.Node

    public init(node: Yams.Node) {
        self.node = node
    }

    /// Parse from raw YAML text. Empty text produces an empty mapping.
    public init(yaml: String) throws {
        let trimmed = yaml.trimmingCharacters(in: .whitespacesAndNewlines)
        let source = trimmed.isEmpty ? "{}" : yaml
        self.node = try Yams.compose(yaml: source) ?? (try Yams.compose(yaml: "{}")!)
    }

    /// Serialize back to YAML text (ends with a trailing newline).
    public func yaml() throws -> String {
        try Yams.serialize(node: node)
    }

    // MARK: Typed accessors

    /// Keys in their original order.
    public var keys: [String] {
        node.mapping?.compactMap { $0.key.string } ?? []
    }

    public subscript(_ key: String) -> Yams.Node? {
        node[key]
    }

    public func string(_ key: String) -> String? {
        node[key]?.string
    }

    /// Reads a value as a list of strings. A single scalar is treated as a
    /// one-element list; a missing key yields an empty list.
    public func stringArray(_ key: String) -> [String] {
        guard let value = node[key] else { return [] }
        if let seq = value.sequence {
            return seq.compactMap { $0.string }
        }
        if let scalar = value.string {
            return [scalar]
        }
        return []
    }
}
