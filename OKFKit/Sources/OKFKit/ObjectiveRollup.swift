import Foundation

/// Rolled-up task progress toward an objective.
public struct ObjectiveRollup: Equatable {
    public let objectiveID: String
    public let total: Int
    /// Task count keyed by status id (a task with no status is keyed `"none"`).
    public let byStatus: [String: Int]
    public let doneCount: Int

    public init(objectiveID: String, total: Int, byStatus: [String: Int], doneCount: Int) {
        self.objectiveID = objectiveID
        self.total = total
        self.byStatus = byStatus
        self.doneCount = doneCount
    }

    /// Fraction of contributing tasks in the schema's `done` status (0 when there are none).
    public var fractionDone: Double {
        total == 0 ? 0 : Double(doneCount) / Double(total)
    }
}

/// Objective hierarchy navigation. Links point *upward*: a project declares the objectives it
/// serves (`objectives: [...]`), a milestone declares its `project`, a task declares its
/// `parent` milestone (and may also list `objectives` directly).
public extension OKFBundle {
    /// All objective concepts, id-sorted.
    func objectives() -> [Concept] { concepts(ofKind: .objective) }

    /// Projects that declare they serve this objective.
    func projects(forObjective objectiveID: String) -> [Concept] {
        concepts(ofKind: .project).filter { $0.objectives.contains(objectiveID) }
    }

    /// Milestones belonging to a project (`project:` equals the project's id).
    func milestones(forProject projectID: String) -> [Concept] {
        concepts(ofKind: .milestone).filter { $0.project == projectID }
    }

    /// Tasks contributing to an objective: those under the milestones of projects that serve
    /// it, plus any task that lists the objective directly. Each task appears once, id-sorted.
    func tasks(forObjective objectiveID: String) -> [Concept] {
        let projectIDs = Set(projects(forObjective: objectiveID).map(\.id))
        let milestoneIDs = Set(
            concepts(ofKind: .milestone)
                .filter { projectIDs.contains($0.project ?? "") }
                .map(\.id)
        )
        return concepts(ofKind: .task).filter { task in
            let underHierarchy = task.parent.map { milestoneIDs.contains($0) } ?? false
            return underHierarchy || task.objectives.contains(objectiveID)
        }
    }

    /// Roll contributing task statuses up to an objective.
    func rollup(forObjective objectiveID: String) -> ObjectiveRollup {
        let tasks = tasks(forObjective: objectiveID)
        var byStatus: [String: Int] = [:]
        for t in tasks { byStatus[t.status ?? "none", default: 0] += 1 }
        let doneCount = schema.taskStatus(for: .done).map { byStatus[$0] ?? 0 } ?? 0
        return ObjectiveRollup(
            objectiveID: objectiveID, total: tasks.count, byStatus: byStatus, doneCount: doneCount)
    }
}
