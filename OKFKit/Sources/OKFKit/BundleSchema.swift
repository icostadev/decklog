import Foundation

/// A semantic role a task status plays in the lifecycle. Code that acts on statuses (the
/// dispatch gate, the executor, the board's blocker/off-board logic) keys off these roles
/// rather than literal strings, so a bundle can rename its statuses without breaking them.
public enum TaskRole: String, CaseIterable, Equatable {
    case ready
    case inProgress = "in_progress"
    case inReview = "in_review"
    case done
    case cancelled
}

/// One status in a bundle's vocabulary: the value written in frontmatter, its display label,
/// whether it appears as a board column, and (for task statuses) the semantic role it fills.
public struct StatusDef: Equatable {
    public let id: String          // the value written in frontmatter
    public let label: String       // display label
    public let isColumn: Bool      // shown as a board column
    public let role: TaskRole?     // semantic role (task statuses only)

    public init(id: String, label: String? = nil, isColumn: Bool = true, role: TaskRole? = nil) {
        self.id = id
        self.label = label ?? Self.defaultLabel(for: id)
        self.isColumn = isColumn
        self.role = role
    }

    /// Derives a display label from an id: `in_progress` → "In progress".
    public static func defaultLabel(for id: String) -> String {
        let spaced = id
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        guard let first = spaced.first else { return spaced }
        return first.uppercased() + spaced.dropFirst()
    }
}

/// The status vocabulary a bundle uses, for tasks / milestones+projects / objectives.
/// `default` reproduces the built-in enums in `Status.swift`; a bundle can override it via a
/// root `decklog.yaml` (loaded in a later task).
public struct BundleSchema: Equatable {
    public let taskStatuses: [StatusDef]       // ordered → board columns
    public let milestoneStatuses: [StatusDef]  // milestones and projects
    public let objectiveStatuses: [StatusDef]

    public init(
        taskStatuses: [StatusDef],
        milestoneStatuses: [StatusDef],
        objectiveStatuses: [StatusDef]
    ) {
        self.taskStatuses = taskStatuses
        self.milestoneStatuses = milestoneStatuses
        self.objectiveStatuses = objectiveStatuses
    }

    /// The built-in vocabulary — identical to `TaskStatus`/`WorkStatus`/`ObjectiveStatus`.
    public static let `default` = BundleSchema(
        taskStatuses: [
            StatusDef(id: "draft"),
            StatusDef(id: "ready", role: .ready),
            StatusDef(id: "in_progress", role: .inProgress),
            StatusDef(id: "in_review", role: .inReview),
            StatusDef(id: "done", role: .done),
            StatusDef(id: "cancelled", isColumn: false, role: .cancelled),
        ],
        milestoneStatuses: [
            StatusDef(id: "planned"),
            StatusDef(id: "active"),
            StatusDef(id: "done"),
            StatusDef(id: "cancelled", isColumn: false),
        ],
        objectiveStatuses: [
            StatusDef(id: "draft"),
            StatusDef(id: "active"),
            StatusDef(id: "achieved"),
            StatusDef(id: "missed"),
        ]
    )

    // MARK: Lookups

    /// Allowed status ids for a kind, or `nil` if the kind has no status vocabulary.
    /// Mirrors the former `StatusVocabulary.allowed(for:)`.
    public func allowedStatuses(for kind: ConceptKind) -> [String]? {
        switch kind {
        case .task:                return taskStatuses.map(\.id)
        case .milestone, .project: return milestoneStatuses.map(\.id)
        case .objective:           return objectiveStatuses.map(\.id)
        default:                   return nil
        }
    }

    /// The task status id filling a semantic role (e.g. `.ready` → "ready"), or `nil` if the
    /// bundle's vocabulary doesn't assign that role.
    public func taskStatus(for role: TaskRole) -> String? {
        taskStatuses.first { $0.role == role }?.id
    }

    /// Task statuses shown as board columns, in declared order.
    public var taskColumns: [StatusDef] {
        taskStatuses.filter(\.isColumn)
    }

    /// Display label for a task status id (falls back to a derived label for unknown ids).
    public func taskLabel(_ id: String) -> String {
        taskStatuses.first { $0.id == id }?.label ?? StatusDef.defaultLabel(for: id)
    }
}
