import Foundation

public enum OKFError: Error, CustomStringConvertible {
    case cannotEnumerate(URL)

    public var description: String {
        switch self {
        case .cannotEnumerate(let url):
            return "Cannot enumerate bundle at \(url.path)"
        }
    }
}

/// An in-memory view of an OKF bundle: all non-reserved concepts keyed by id,
/// plus derived graph queries. Read-only for Iteration 1.
public struct OKFBundle {
    public let rootURL: URL
    public private(set) var concepts: [String: Concept]
    public var okfVersion: String?

    /// Files that are reserved by OKF and are never concepts.
    static let reservedFilenames: Set<String> = ["index.md", "log.md"]

    public init(rootURL: URL, concepts: [String: Concept], okfVersion: String? = nil) {
        self.rootURL = rootURL
        self.concepts = concepts
        self.okfVersion = okfVersion
    }

    /// Build a bundle from concepts without touching disk (useful for tests).
    public static func inMemory(_ list: [Concept]) -> OKFBundle {
        var byID: [String: Concept] = [:]
        for c in list { byID[c.id] = c }
        return OKFBundle(rootURL: URL(fileURLWithPath: "/"), concepts: byID)
    }

    // MARK: Queries

    public var allConcepts: [Concept] {
        concepts.values.sorted { $0.id < $1.id }
    }

    public func concept(_ id: String) -> Concept? {
        concepts[id]
    }

    public func concepts(ofKind kind: ConceptKind) -> [Concept] {
        allConcepts.filter { $0.kind == kind }
    }

    /// The derived inverse of `blocked_by`: concepts that this one blocks.
    public func blocks(of id: String) -> [String] {
        allConcepts.filter { $0.blockedBy.contains(id) }.map(\.id)
    }

    // MARK: Loading

    public static func load(at rootURL: URL) throws -> OKFBundle {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isRegularFileKey]
        ) else {
            throw OKFError.cannotEnumerate(rootURL)
        }

        var concepts: [String: Concept] = [:]
        for case let url as URL in enumerator {
            guard url.pathExtension == "md" else { continue }
            guard !reservedFilenames.contains(url.lastPathComponent) else { continue }

            let relative = relativePath(of: url, from: rootURL)
            let id = String(relative.dropLast(3)) // drop ".md"
            let raw = try String(contentsOf: url, encoding: .utf8)
            concepts[id] = try Concept.parse(id: id, raw: raw)
        }

        let version = rootOKFVersion(at: rootURL)
        return OKFBundle(rootURL: rootURL, concepts: concepts, okfVersion: version)
    }

    /// The single place `okf_version` may live: the root `index.md` frontmatter.
    private static func rootOKFVersion(at rootURL: URL) -> String? {
        let indexURL = rootURL.appendingPathComponent("index.md")
        guard let raw = try? String(contentsOf: indexURL, encoding: .utf8) else { return nil }
        let file = MarkdownFile(raw: raw)
        guard let text = file.frontmatterText,
              let fm = try? Frontmatter(yaml: text) else { return nil }
        return fm.string("okf_version")
    }

    private static func relativePath(of url: URL, from base: URL) -> String {
        let baseParts = base.standardizedFileURL.pathComponents
        let urlParts = url.standardizedFileURL.pathComponents
        var i = 0
        while i < baseParts.count, i < urlParts.count, baseParts[i] == urlParts[i] {
            i += 1
        }
        return urlParts[i...].joined(separator: "/")
    }
}
