import Foundation

/// A single OKF concept: one markdown file with YAML frontmatter and a body.
/// Its `id` is the file path relative to the bundle root, minus the `.md` extension
/// (e.g. `projects/checkout-revamp/tasks/apple-pay`).
public struct Concept: Identifiable {
    public let id: String
    public var frontmatter: Frontmatter
    public var body: String

    public init(id: String, frontmatter: Frontmatter, body: String) {
        self.id = id
        self.frontmatter = frontmatter
        self.body = body
    }

    /// Parse a concept from raw file contents.
    public static func parse(id: String, raw: String) throws -> Concept {
        let file = MarkdownFile(raw: raw)
        let fm = try Frontmatter(yaml: file.frontmatterText ?? "")
        return Concept(id: id, frontmatter: fm, body: file.body)
    }

    /// Serialize back to file contents. Frontmatter key order and unknown keys are
    /// preserved; comments are not (see `Frontmatter`).
    public func serialized() throws -> String {
        let yaml = try frontmatter.yaml() // ends with a trailing newline
        return "---\n\(yaml)---\n\(body)"
    }

    // MARK: Typed field accessors (the Decklog extension vocabulary)

    public var type: String { frontmatter.string("type") ?? "" }
    public var kind: ConceptKind { ConceptKind(type: type) }
    public var title: String { frontmatter.string("title") ?? id }
    public var summary: String? { frontmatter.string("description") }
    public var tags: [String] { frontmatter.stringArray("tags") }

    public var status: String? { frontmatter.string("status") }
    public var assignee: String? { frontmatter.string("assignee") }
    public var priority: String? { frontmatter.string("priority") }
    public var order: String? { frontmatter.string("order") }

    public var start: String? { frontmatter.string("start") }
    public var due: String? { frontmatter.string("due") }

    public var parent: String? { frontmatter.string("parent") }
    public var blockedBy: [String] { frontmatter.stringArray("blocked_by") }
    public var relatesTo: [String] { frontmatter.stringArray("relates_to") }
    public var artifacts: [String] { frontmatter.stringArray("artifacts") }

    public var cycle: String? { frontmatter.string("cycle") }
    public var project: String? { frontmatter.string("project") }
    public var objectives: [String] { frontmatter.stringArray("objectives") }
    public var repo: String? { frontmatter.string("repo") }
}
