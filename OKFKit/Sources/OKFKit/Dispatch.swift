import Foundation

/// Result of the dispatch gate: whether a task may be handed to an executor, and if
/// not, the human-readable reasons.
public struct DispatchDecision: Equatable {
    public let canDispatch: Bool
    public let reasons: [String]
}

public extension OKFBundle {
    /// A task is dispatchable only when it is `ready` **and** every `blocked_by` is
    /// `done` (DESIGN §9 — a hard gate, not a warning).
    func dispatchDecision(forTask id: String) -> DispatchDecision {
        guard let task = concept(id), task.kind == .task else {
            return DispatchDecision(canDispatch: false, reasons: ["`\(id)` is not a task"])
        }
        var reasons: [String] = []
        let readyStatus = schema.taskStatus(for: .ready)
        if task.status != readyStatus {
            reasons.append("status is `\(task.status ?? "none")`, not `\(readyStatus ?? "ready")`")
        }
        let doneStatus = schema.taskStatus(for: .done)
        for blocker in task.blockedBy {
            let status = concept(blocker)?.status
            if status != doneStatus {
                reasons.append("blocked by `\(blocker)` (\(status ?? "missing"))")
            }
        }
        return DispatchDecision(canDispatch: reasons.isEmpty, reasons: reasons)
    }
}

/// The git branch an executor works on for a task.
public enum ExecutorBranch {
    public static func name(forTask id: String) -> String {
        "decklog/" + id.replacingOccurrences(of: "/", with: "-")
    }
}
