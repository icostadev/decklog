import Foundation

/// Task lifecycle (DESIGN.md §4). A task is dispatchable only when `ready` and all
/// blockers are `done` (enforced by the app, not this model). "Blocked" is not a
/// status — it is derived from unresolved `blocked_by` and shown as a badge.
public enum TaskStatus: String, CaseIterable {
    case draft
    case ready
    case inProgress = "in_progress"
    case inReview = "in_review"
    case done
    case cancelled
}

/// Milestone / Project coarse status (not dispatched, not reviewed).
public enum WorkStatus: String, CaseIterable {
    case planned
    case active
    case done
    case cancelled
}

/// Objective status (OKR-style; `missed` is an outcome, not a failure).
public enum ObjectiveStatus: String, CaseIterable {
    case draft
    case active
    case achieved
    case missed
}

enum StatusVocabulary {
    /// Allowed raw status values for a kind, or `nil` if the kind has no status.
    static func allowed(for kind: ConceptKind) -> [String]? {
        switch kind {
        case .task:
            return TaskStatus.allCases.map(\.rawValue)
        case .milestone, .project:
            return WorkStatus.allCases.map(\.rawValue)
        case .objective:
            return ObjectiveStatus.allCases.map(\.rawValue)
        default:
            return nil
        }
    }
}
