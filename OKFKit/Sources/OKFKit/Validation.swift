import Foundation

/// A single advisory finding from the validation pass. Validation never mutates or
/// blocks: the bundle remains usable with warnings (DESIGN.md §7).
public struct ValidationIssue: Equatable {
    public enum Severity: String { case warning, error }

    public let severity: Severity
    public let conceptID: String
    public let message: String

    public init(severity: Severity, conceptID: String, message: String) {
        self.severity = severity
        self.conceptID = conceptID
        self.message = message
    }
}

public extension OKFBundle {
    /// Runs all checks and returns advisory issues. Order is deterministic.
    func validate() -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        for c in allConcepts {
            checkDanglingRef(c.parent, field: "parent", in: c, into: &issues)
            checkDanglingRef(c.assignee, field: "assignee", in: c, into: &issues)
            for blocker in c.blockedBy {
                checkDanglingRef(blocker, field: "blocked_by", in: c, into: &issues)
            }

            if let statusIssue = statusIssue(for: c) {
                issues.append(statusIssue)
            }
            issues.append(contentsOf: placementIssues(for: c))
            issues.append(contentsOf: dateIssues(for: c))
        }

        issues.append(contentsOf: cycleIssues(label: "parent") { $0.parent.map { [$0] } ?? [] })
        issues.append(contentsOf: cycleIssues(label: "blocked_by") { $0.blockedBy })

        return issues
    }

    // MARK: Individual checks

    private func checkDanglingRef(
        _ ref: String?, field: String, in c: Concept, into issues: inout [ValidationIssue]
    ) {
        guard let ref, !ref.isEmpty else { return }
        if concepts[ref] == nil {
            issues.append(.init(
                severity: .warning,
                conceptID: c.id,
                message: "\(field) → missing concept `\(ref)`"
            ))
        }
    }

    private func statusIssue(for c: Concept) -> ValidationIssue? {
        guard let status = c.status,
              let allowed = StatusVocabulary.allowed(for: c.kind) else { return nil }
        guard !allowed.contains(status) else { return nil }
        return .init(
            severity: .warning,
            conceptID: c.id,
            message: "unknown status `\(status)` for type `\(c.type)`"
        )
    }

    /// Flags concepts that silently disappear from the board: a file under a `tasks/`
    /// directory that isn't typed as a task (so it's not a `.task` at all), or a task with
    /// no `status` (so it can't sit in a lifecycle column — it lands under "Unplaced").
    private func placementIssues(for c: Concept) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []

        if Self.isUnderTasksDir(c.id), c.kind != .task {
            let shown = c.type.isEmpty ? "none" : "`\(c.type)`"
            issues.append(.init(
                severity: .warning,
                conceptID: c.id,
                message: "under tasks/ but type is \(shown) — expected `task`; it won't appear on the board"
            ))
        }

        if c.kind == .task, (c.status ?? "").isEmpty {
            issues.append(.init(
                severity: .warning,
                conceptID: c.id,
                message: "no `status` set — shown under \u{201C}Unplaced\u{201D}"
            ))
        }

        return issues
    }

    /// True when the file sits directly in a `tasks/` directory (its parent path component
    /// is `tasks`), e.g. `projects/x/tasks/task-001`.
    private static func isUnderTasksDir(_ id: String) -> Bool {
        let parts = id.split(separator: "/")
        return parts.count >= 2 && String(parts[parts.count - 2]) == "tasks"
    }

    private func dateIssues(for c: Concept) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        // ISO `YYYY-MM-DD` sorts correctly as strings.
        if let start = c.start, let due = c.due, start > due {
            issues.append(.init(
                severity: .warning,
                conceptID: c.id,
                message: "start (\(start)) is after due (\(due))"
            ))
        }
        // A task's due date should not exceed its milestone parent's.
        if c.kind == .task, let due = c.due,
           let parentID = c.parent, let parent = concepts[parentID],
           parent.kind == .milestone, let parentDue = parent.due, due > parentDue {
            issues.append(.init(
                severity: .warning,
                conceptID: c.id,
                message: "due (\(due)) is after milestone `\(parentID)` due (\(parentDue))"
            ))
        }
        return issues
    }

    /// Detects directed cycles over an edge function (e.g. `parent`, `blocked_by`).
    private func cycleIssues(label: String, edges: (Concept) -> [String]) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        var state: [String: Int] = [:] // 0 = in progress, 1 = done

        func visit(_ id: String, path: inout [String]) {
            state[id] = 0
            path.append(id)
            if let c = concepts[id] {
                for next in edges(c) where concepts[next] != nil {
                    if state[next] == 0 {
                        issues.append(.init(
                            severity: .error,
                            conceptID: id,
                            message: "\(label) cycle: \((path + [next]).joined(separator: " → "))"
                        ))
                    } else if state[next] == nil {
                        visit(next, path: &path)
                    }
                }
            }
            path.removeLast()
            state[id] = 1
        }

        for id in concepts.keys.sorted() where state[id] == nil {
            var path: [String] = []
            visit(id, path: &path)
        }
        return issues
    }
}
