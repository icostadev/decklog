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

/// A file that could not be loaded (e.g. malformed YAML frontmatter). Tolerant load
/// quarantines it and loads the rest of the bundle.
public struct BundleLoadError: Equatable {
    public let path: String   // relative to the bundle root
    public let message: String

    public init(path: String, message: String) {
        self.path = path
        self.message = message
    }
}

/// An in-memory view of an OKF bundle: all non-reserved concepts keyed by id,
/// plus derived graph queries. Read-only for Iteration 1.
public struct OKFBundle {
    public let rootURL: URL
    public private(set) var concepts: [String: Concept]
    public var okfVersion: String?
    /// The status vocabulary this bundle uses (from `decklog.yaml`, or the built-in default).
    public let schema: BundleSchema
    /// Files that failed to load (tolerant load), path + reason.
    public private(set) var loadErrors: [BundleLoadError]

    /// Files that are reserved by OKF and are never concepts.
    static let reservedFilenames: Set<String> = ["index.md", "log.md"]

    public init(
        rootURL: URL,
        concepts: [String: Concept],
        okfVersion: String? = nil,
        schema: BundleSchema = .default,
        loadErrors: [BundleLoadError] = []
    ) {
        self.rootURL = rootURL
        self.concepts = concepts
        self.okfVersion = okfVersion
        self.schema = schema
        self.loadErrors = loadErrors
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
        var loadErrors: [BundleLoadError] = []
        for case let url as URL in enumerator {
            guard url.pathExtension == "md" else { continue }
            guard !reservedFilenames.contains(url.lastPathComponent) else { continue }

            let relative = relativePath(of: url, from: rootURL)
            let id = String(relative.dropLast(3)) // drop ".md"
            do {
                let raw = try String(contentsOf: url, encoding: .utf8)
                concepts[id] = try Concept.parse(id: id, raw: raw)
            } catch {
                // Tolerant load: quarantine this file, keep loading the rest.
                loadErrors.append(BundleLoadError(path: relative, message: "\(error)"))
            }
        }

        let version = rootOKFVersion(at: rootURL)
        let schema = loadSchema(at: rootURL, into: &loadErrors)
        return OKFBundle(
            rootURL: rootURL, concepts: concepts, okfVersion: version,
            schema: schema,
            loadErrors: loadErrors.sorted { $0.path < $1.path }
        )
    }

    /// Reads the bundle's status vocabulary from a root `decklog.yaml`. Tolerant: an absent
    /// file uses the built-in default; a malformed one falls back to the default and records a
    /// load error (so it surfaces alongside quarantined files).
    private static func loadSchema(at rootURL: URL, into loadErrors: inout [BundleLoadError]) -> BundleSchema {
        let url = rootURL.appendingPathComponent("decklog.yaml")
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else {
            return .default
        }
        do {
            return try BundleSchema.parse(yaml: raw)
        } catch {
            loadErrors.append(BundleLoadError(path: "decklog.yaml", message: "\(error)"))
            return .default
        }
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
