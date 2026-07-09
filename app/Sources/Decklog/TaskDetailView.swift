import SwiftUI
import OKFKit
import MarkdownUI

struct TaskDetailView: View {
    let task: Concept
    let bundle: OKFBundle
    @EnvironmentObject var store: BundleStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(task.title).font(.title2).bold()
                fields
                executionSection
                Divider()
                Markdown(task.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle(task.title)
    }

    @ViewBuilder
    private var executionSection: some View {
        if task.kind == .task { taskExecution }
    }

    private var taskExecution: some View {
        let decision = bundle.dispatchDecision(forTask: task.id)
        let repoURL = bundle.project(forTask: task.id).flatMap { bundle.repoURL(forProject: $0.id) }
        let session = store.executors[task.id]
        let running = session.map { [.preparing, .running, .committing].contains($0.phase) } ?? false
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Button { store.dispatch(taskID: task.id) } label: {
                    Label(running ? "Running…" : "Run", systemImage: "play.fill")
                }
                .disabled(!decision.canDispatch || repoURL == nil || running)
                if let phase = session?.phase, phase != .review {
                    Text(phase.rawValue).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            if !decision.canDispatch {
                Label(decision.reasons.joined(separator: "; "), systemImage: "lock")
                    .font(.caption).foregroundStyle(.secondary)
            } else if repoURL == nil {
                Label("No local repo linked to this project", systemImage: "questionmark.folder")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let session { ExecutorLogView(session: session) }
        }
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("Type", task.type)
            if let status = task.status { row("Status", status) }
            if let priority = task.priority { row("Priority", priority) }
            if let assignee = task.assignee { row("Assignee", assignee) }
            if let start = task.start { row("Start", start) }
            if let due = task.due { row("Due", due) }
            if !task.blockedBy.isEmpty {
                row("Blocked by", task.blockedBy.joined(separator: ", "))
            }
            if !task.artifacts.isEmpty {
                HStack(alignment: .top) {
                    Text("Artifacts")
                        .foregroundStyle(.secondary)
                        .frame(width: 90, alignment: .leading)
                    VStack(alignment: .leading) {
                        ForEach(task.artifacts, id: \.self) { artifact in
                            if let url = URL(string: artifact) {
                                Link(artifact, destination: url)
                            } else {
                                Text(artifact)
                            }
                        }
                    }
                }
                .font(.callout)
            }
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            Text(value)
            Spacer(minLength: 0)
        }
        .font(.callout)
    }
}

/// Live output of an executor run: assistant text, tool activity, and status lines.
struct ExecutorLogView: View {
    @ObservedObject var session: ExecutorSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(session.log) { line in
                switch line.kind {
                case .output:
                    Text(line.text).font(.caption).textSelection(.enabled)
                case .activity:
                    Label(line.text, systemImage: "wrench.and.screwdriver")
                        .font(.caption2).foregroundStyle(.secondary)
                case .system:
                    Label(line.text, systemImage: "info.circle")
                        .font(.caption2).foregroundStyle(.secondary)
                case .error:
                    Label(line.text, systemImage: "exclamationmark.triangle")
                        .font(.caption2).foregroundStyle(.red).textSelection(.enabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .textBackgroundColor)))
    }
}
