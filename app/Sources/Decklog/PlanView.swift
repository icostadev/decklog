import SwiftUI
import OKFKit

/// The "Plan" view: every project's tasks in dependency (`blocked_by`) order, so reading
/// top-to-bottom is the execution sequence. Each project header shows the objective(s) it
/// serves; each task shows its status and blockers, and drills into the task detail.
struct PlanView: View {
    let bundle: OKFBundle

    private var projects: [Concept] { bundle.concepts(ofKind: .project) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if projects.isEmpty {
                    Text("No projects yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(projects) { project in
                        projectSection(project)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Plan")
    }

    @ViewBuilder
    private func projectSection(_ project: Concept) -> some View {
        let tasks = bundle.planOrder(bundle.tasks(inProject: project.id))
        VStack(alignment: .leading, spacing: 8) {
            header(project)
            if tasks.isEmpty {
                Text("No tasks.").font(.callout).foregroundStyle(.secondary)
            } else {
                ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                    row(index + 1, task)
                    if task.id != tasks.last?.id { Divider() }
                }
            }
        }
    }

    private func header(_ project: Concept) -> some View {
        HStack(spacing: 8) {
            Label(project.title, systemImage: "folder").font(.headline)
            Spacer(minLength: 8)
            ForEach(objectiveTitles(project), id: \.self) { title in
                Badge(text: title, systemImage: "target")
            }
        }
    }

    private func row(_ ordinal: Int, _ task: Concept) -> some View {
        NavigationLink(value: task.id) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(ordinal).")
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title).font(.callout)
                    if let blockers = blockerLabel(task) {
                        Label("blocked by: \(blockers)", systemImage: "lock")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                Spacer(minLength: 8)
                if let status = task.status {
                    Text(bundle.schema.taskLabel(status))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func objectiveTitles(_ project: Concept) -> [String] {
        project.objectives.compactMap { bundle.concept($0)?.title }
    }

    private func blockerLabel(_ task: Concept) -> String? {
        let names = task.blockedBy.map { bundle.concept($0)?.title ?? $0 }
        return names.isEmpty ? nil : names.joined(separator: ", ")
    }
}
