import SwiftUI
import OKFKit

/// The read-only task board. Columns are the task lifecycle; cards cannot be dragged
/// (all mutation goes through the PM agent — not built until Iteration 2).
struct BoardView: View {
    let bundle: OKFBundle
    let projectID: String?

    // `cancelled` is intentionally off-board; `blocked` is a derived card badge.
    private static let columns: [TaskStatus] = [
        .draft, .ready, .inProgress, .inReview, .done,
    ]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(Self.columns, id: \.self) { status in
                    ColumnView(
                        title: Self.label(status),
                        tasks: tasks(in: status),
                        bundle: bundle
                    )
                }
            }
            .padding()
        }
        .navigationTitle(scopeTitle)
    }

    // MARK: Scoping + grouping

    private var scopedTasks: [Concept] {
        let all = bundle.concepts(ofKind: .task)
        guard let projectID, let dir = Self.projectDir(projectID) else { return all }
        return all.filter { $0.id.hasPrefix(dir + "/") }
    }

    private func tasks(in status: TaskStatus) -> [Concept] {
        scopedTasks
            .filter { $0.status == status.rawValue }
            .sorted { lhs, rhs in
                let l = lhs.order ?? ""
                let r = rhs.order ?? ""
                return l == r ? lhs.title < rhs.title : l < r
            }
    }

    /// `projects/x/project` → `projects/x`
    private static func projectDir(_ projectID: String) -> String? {
        guard let slash = projectID.lastIndex(of: "/") else { return nil }
        return String(projectID[..<slash])
    }

    private var scopeTitle: String {
        if let projectID, let project = bundle.concept(projectID) { return project.title }
        return "All tasks"
    }

    private static func label(_ status: TaskStatus) -> String {
        switch status {
        case .inProgress: return "In progress"
        case .inReview: return "In review"
        default: return status.rawValue.capitalized
        }
    }
}

struct ColumnView: View {
    let title: String
    let tasks: [Concept]
    let bundle: OKFBundle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(tasks.count)").font(.caption).foregroundStyle(.secondary)
            }
            ForEach(tasks) { task in
                NavigationLink(value: task.id) {
                    TaskCard(task: task, bundle: bundle)
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
        .frame(width: 240, alignment: .leading)
    }
}

struct TaskCard: View {
    let task: Concept
    let bundle: OKFBundle

    private var hasOpenBlockers: Bool {
        task.blockedBy.contains { bundle.concept($0)?.status != TaskStatus.done.rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(task.title).font(.callout).fontWeight(.medium)
            HStack(spacing: 6) {
                if let priority = task.priority {
                    Badge(text: priority.uppercased())
                }
                if let assignee = task.assignee {
                    Badge(
                        text: assignee.replacingOccurrences(of: "agents/", with: "@"),
                        systemImage: "cpu"
                    )
                }
                if hasOpenBlockers {
                    Badge(text: "blocked", systemImage: "lock", tint: .orange)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
        .contentShape(Rectangle())
    }
}

struct Badge: View {
    let text: String
    var systemImage: String?
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 3) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text)
        }
        .font(.caption2)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Capsule().fill(tint.opacity(0.15)))
        .foregroundStyle(tint)
    }
}
