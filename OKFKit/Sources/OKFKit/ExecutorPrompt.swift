import Foundation

/// Builds the prompt handed to a task executor: the task spec plus the resolved bodies
/// of the concepts its `## Context` section links to (DESIGN §9 — context is injected
/// with linked concepts resolved).
public enum ExecutorPrompt {
    public static func build(forTask task: Concept, in bundle: OKFBundle) -> String {
        var parts: [String] = ["# Task: \(task.title)"]
        if let summary = task.summary { parts.append(summary) }
        if !task.body.isEmpty { parts.append(task.body) }

        let contextIDs = contextConceptIDs(forTask: task, in: bundle)
        if !contextIDs.isEmpty {
            parts.append("---\n\n# Referenced context")
            for id in contextIDs {
                guard let concept = bundle.concept(id) else { continue }
                parts.append("## \(concept.title) (`\(id)`)\n\n\(concept.body)")
            }
        }
        return parts.joined(separator: "\n\n")
    }

    /// Concept ids linked from the task's `## Context` section that resolve in the bundle.
    public static func contextConceptIDs(forTask task: Concept, in bundle: OKFBundle) -> [String] {
        guard let section = contextSection(of: task.body) else { return [] }
        var ids: [String] = []
        var seen = Set<String>()
        for target in markdownLinkTargets(in: section) {
            let id = normalize(target)
            if !id.isEmpty, bundle.concept(id) != nil, seen.insert(id).inserted {
                ids.append(id)
            }
        }
        return ids
    }

    // MARK: - Helpers

    /// Text under a `## Context` heading, up to the next `## ` heading (or end).
    private static func contextSection(of body: String) -> String? {
        let lines = body.components(separatedBy: "\n")
        guard let start = lines.firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces).lowercased() == "## context"
        }) else { return nil }
        var collected: [String] = []
        for line in lines[(start + 1)...] {
            if line.hasPrefix("## ") { break }
            collected.append(line)
        }
        return collected.joined(separator: "\n")
    }

    private static func markdownLinkTargets(in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: "\\]\\(([^)]+)\\)") else { return [] }
        let ns = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: ns.length)).map {
            ns.substring(with: $0.range(at: 1))
        }
    }

    /// A markdown link target → a concept id (strip anchor, leading `/`, trailing `.md`).
    private static func normalize(_ target: String) -> String {
        var t = target.trimmingCharacters(in: .whitespaces)
        if let hash = t.firstIndex(of: "#") { t = String(t[..<hash]) }
        if t.hasPrefix("/") { t.removeFirst() }
        if t.hasSuffix(".md") { t = String(t.dropLast(3)) }
        return t
    }
}
