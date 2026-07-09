import SwiftUI
import OKFKit
import MarkdownUI

struct TaskDetailView: View {
    let task: Concept
    let bundle: OKFBundle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(task.title).font(.title2).bold()
                fields
                Divider()
                Markdown(task.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .navigationTitle(task.title)
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
