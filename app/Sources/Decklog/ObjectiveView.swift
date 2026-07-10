import SwiftUI
import OKFKit

/// Detail for a single objective: status, rolled-up task progress, the projects that serve
/// it, and its contributing tasks (which drill into the task detail).
struct ObjectiveView: View {
    let objective: Concept
    let bundle: OKFBundle

    private var rollup: ObjectiveRollup { bundle.rollup(forObjective: objective.id) }
    private var projects: [Concept] { bundle.projects(forObjective: objective.id) }
    private var tasks: [Concept] { bundle.tasks(forObjective: objective.id) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                progress
                if !projects.isEmpty { projectsSection }
                tasksSection
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(objective.title)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(objective.title).font(.title2).fontWeight(.semibold)
                if let status = objective.status { Badge(text: status.capitalized) }
            }
            if let summary = objective.summary {
                Text(summary).foregroundStyle(.secondary)
            }
        }
    }

    private var progress: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Progress").font(.headline)
                Spacer()
                Text(rollup.total == 0 ? "No tasks" : "\(rollup.doneCount) of \(rollup.total) done")
                    .font(.caption).foregroundStyle(.secondary)
            }
            ProgressView(value: rollup.fractionDone)
            if !statusBreakdown.isEmpty {
                HStack(spacing: 6) {
                    ForEach(statusBreakdown) { item in
                        Badge(text: "\(bundle.schema.taskLabel(item.status)) \(item.count)")
                    }
                }
            }
        }
    }

    private struct StatusCount: Identifiable {
        let status: String
        let count: Int
        var id: String { status }
    }

    /// Status counts ordered by the schema's task-status order (unknown/`none` last).
    private var statusBreakdown: [StatusCount] {
        let order = bundle.schema.taskStatuses.map(\.id)
        return rollup.byStatus
            .sorted { a, b in
                let ia = order.firstIndex(of: a.key) ?? Int.max
                let ib = order.firstIndex(of: b.key) ?? Int.max
                return ia == ib ? a.key < b.key : ia < ib
            }
            .map { StatusCount(status: $0.key, count: $0.value) }
    }

    private var projectsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Projects").font(.headline)
            ForEach(projects) { project in
                Label(project.title, systemImage: "folder").font(.callout)
            }
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tasks").font(.headline)
            if tasks.isEmpty {
                Text("No tasks are linked to this objective yet.")
                    .foregroundStyle(.secondary).font(.callout)
            } else {
                ForEach(tasks) { task in
                    NavigationLink(value: task.id) {
                        HStack {
                            Text(task.title).font(.callout)
                            Spacer()
                            if let status = task.status {
                                Text(bundle.schema.taskLabel(status))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider()
                }
            }
        }
    }
}
