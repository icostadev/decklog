import Foundation
import Yams

// Writing bundle content back to disk + resolving a project's repo. Used by the
// executor dispatcher to advance a task's lifecycle and locate its working directory.

public extension Frontmatter {
    /// Set (or add) a scalar string field, preserving other keys and their order.
    mutating func set(_ key: String, to value: String) {
        node[key] = Node(value)
    }

    /// Set (or add) a list-of-strings field.
    mutating func set(_ key: String, toList values: [String]) {
        node[key] = Node(values.map { Node($0) })
    }
}

public extension Concept {
    mutating func set(status: String) { frontmatter.set("status", to: status) }
    mutating func set(artifacts: [String]) { frontmatter.set("artifacts", toList: artifacts) }
}

public extension OKFBundle {
    func fileURL(forConcept id: String) -> URL {
        rootURL.appendingPathComponent(id + ".md")
    }

    /// Persist a concept back to its markdown file (frontmatter + body).
    func write(_ concept: Concept) throws {
        try concept.serialized().write(
            to: fileURL(forConcept: concept.id), atomically: true, encoding: .utf8
        )
    }

    /// The project a task belongs to, matched by id prefix
    /// (`projects/x/tasks/y` → the project whose dir is `projects/x`).
    func project(forTask taskID: String) -> Concept? {
        concepts(ofKind: .project).first { project in
            let dir = project.id.split(separator: "/").dropLast().joined(separator: "/")
            return !dir.isEmpty && taskID.hasPrefix(dir + "/")
        }
    }

    /// The local working directory for a project's `repo`, or nil if it's a remote URL
    /// (which would need cloning — not supported for local-branch execution yet).
    /// Relative paths (e.g. `..`) resolve against the bundle root.
    func repoURL(forProject id: String) -> URL? {
        guard let repo = concept(id)?.repo, !repo.isEmpty else { return nil }
        if repo.contains("://") || repo.hasPrefix("git@") { return nil }
        if repo.hasPrefix("/") { return URL(fileURLWithPath: repo).standardizedFileURL }
        // Relative to the bundle root (which is a directory).
        return rootURL.appendingPathComponent(repo).standardizedFileURL
    }
}
