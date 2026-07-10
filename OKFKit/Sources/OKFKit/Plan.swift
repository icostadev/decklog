import Foundation

/// Sequencing helpers: a project's tasks in dependency order for the Plan view.
public extension OKFBundle {
    /// Tasks that live under a project's directory (path-based, matching the board's scoping —
    /// includes tasks not attached to a milestone).
    func tasks(inProject projectID: String) -> [Concept] {
        guard let dir = Self.projectDirectory(projectID) else { return [] }
        return concepts(ofKind: .task).filter { $0.id.hasPrefix(dir + "/") }
    }

    /// Orders tasks so each appears after the tasks it is `blocked_by` — a topological sort, so
    /// reading top-to-bottom is the execution sequence. Independent tasks keep a stable order
    /// (`order` field, then id). Blockers outside the given set are ignored for ordering, and
    /// dependency cycles are tolerated (no infinite loop).
    func planOrder(_ tasks: [Concept]) -> [Concept] {
        let ids = Set(tasks.map(\.id))
        let byID = Dictionary(tasks.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })

        func before(_ a: Concept, _ b: Concept) -> Bool {
            let oa = a.order ?? "", ob = b.order ?? ""
            return oa == ob ? a.id < b.id : oa < ob
        }

        var result: [Concept] = []
        var state: [String: Int] = [:]  // 0 = visiting, 1 = done
        func visit(_ id: String) {
            guard state[id] == nil, let c = byID[id] else { return } // nil-guard also breaks cycles
            state[id] = 0
            let deps = c.blockedBy.filter { ids.contains($0) }.compactMap { byID[$0] }.sorted(by: before)
            for dep in deps { visit(dep.id) }
            result.append(c)
            state[id] = 1
        }
        for c in tasks.sorted(by: before) { visit(c.id) }
        return result
    }

    /// `projects/x/project` → `projects/x` (the directory tasks live under).
    private static func projectDirectory(_ projectID: String) -> String? {
        guard let slash = projectID.lastIndex(of: "/") else { return nil }
        return String(projectID[..<slash])
    }
}
