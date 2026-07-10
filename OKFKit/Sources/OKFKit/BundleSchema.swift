import Foundation
import Yams

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

/// A problem parsing `decklog.yaml`. Surfaced tolerantly (fall back to `.default`).
public enum SchemaError: Error, CustomStringConvertible {
    case notAList(section: String)
    case missingID(section: String)
    case unknownRole(String)

    public var description: String {
        switch self {
        case .notAList(let s):   return "`\(s)` must be a list of statuses"
        case .missingID(let s):  return "a status entry in `\(s)` is missing its `id`"
        case .unknownRole(let r):
            return "unknown role `\(r)` (expected one of: "
                + TaskRole.allCases.map(\.rawValue).joined(separator: ", ") + ")"
        }
    }
}

public extension BundleSchema {
    /// Parse a `decklog.yaml`. Empty input or any missing section falls back to the built-in
    /// default for that section. Throws `SchemaError` on a malformed section.
    static func parse(yaml: String) throws -> BundleSchema {
        guard !yaml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let node = try Yams.compose(yaml: yaml), node.mapping != nil else {
            return .default
        }
        return BundleSchema(
            taskStatuses: try node["task_statuses"].map { try parseTaskStatuses($0) }
                ?? BundleSchema.default.taskStatuses,
            milestoneStatuses: try node["milestone_statuses"].map { try parseSimpleStatuses($0, section: "milestone_statuses") }
                ?? BundleSchema.default.milestoneStatuses,
            objectiveStatuses: try node["objective_statuses"].map { try parseSimpleStatuses($0, section: "objective_statuses") }
                ?? BundleSchema.default.objectiveStatuses
        )
    }

    /// The role a status id fills in the built-in vocabulary, used to auto-bind a role when a
    /// `decklog.yaml` entry doesn't state one (e.g. `- ready` binds `.ready`).
    private static func defaultRole(forID id: String) -> TaskRole? {
        BundleSchema.default.taskStatuses.first { $0.id == id }?.role
    }

    private static func parseTaskStatuses(_ node: Yams.Node) throws -> [StatusDef] {
        guard let seq = node.sequence else { throw SchemaError.notAList(section: "task_statuses") }
        return try seq.map { element in
            // Shorthand: a bare string is the id; role auto-binds; cancelled is off-board.
            if let id = element.string {
                let role = defaultRole(forID: id)
                return StatusDef(id: id, isColumn: role != .cancelled, role: role)
            }
            guard let id = element["id"]?.string else {
                throw SchemaError.missingID(section: "task_statuses")
            }
            let role: TaskRole?
            if let raw = element["role"]?.string {
                guard let parsed = TaskRole(rawValue: raw) else { throw SchemaError.unknownRole(raw) }
                role = parsed
            } else {
                role = defaultRole(forID: id)
            }
            return StatusDef(
                id: id,
                label: element["label"]?.string,
                isColumn: element["column"]?.bool ?? (role != .cancelled),
                role: role
            )
        }
    }

    private static func parseSimpleStatuses(_ node: Yams.Node, section: String) throws -> [StatusDef] {
        guard let seq = node.sequence else { throw SchemaError.notAList(section: section) }
        return try seq.map { element in
            if let id = element.string { return StatusDef(id: id) }
            guard let id = element["id"]?.string else { throw SchemaError.missingID(section: section) }
            return StatusDef(
                id: id,
                label: element["label"]?.string,
                isColumn: element["column"]?.bool ?? true
            )
        }
    }
}
