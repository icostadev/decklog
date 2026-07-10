import SwiftUI
import OKFKit

/// The read-only task board. Columns are the task lifecycle; cards cannot be dragged
/// (all mutation goes through the PM agent — not built until Iteration 2).
struct BoardView: View {
    let bundle: OKFBundle
    let projectID: String?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 12) {
                // Columns come from the bundle's schema (decklog.yaml or the built-in default);
                // off-board statuses (e.g. cancelled) declare `column: false`.
                ForEach(bundle.schema.taskColumns, id: \.id) { col in
                    ColumnView(
                        title: col.label,
                        tasks: tasks(withStatus: col.id),
                        bundle: bundle
                    )
                }
                // Any task whose status isn't declared in the schema (missing or unknown)
                // would otherwise vanish from the board. Surface it here so an imperfect
                // bundle reads as imperfect, not empty. Only shown when non-empty.
                if !unplacedTasks.isEmpty {
                    ColumnView(
                        title: "Unplaced",
                        systemImage: "questionmark.circle",
                        tint: .orange,
                        tasks: unplacedTasks,
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

    private func tasks(withStatus id: String) -> [Concept] {
        scopedTasks
            .filter { $0.status == id }
            .sorted { lhs, rhs in
                let l = lhs.order ?? ""
                let r = rhs.order ?? ""
                return l == r ? lhs.title < rhs.title : l < r
            }
    }

    /// Tasks whose status isn't declared in the schema (missing or unknown). A status that's
    /// declared but off-board (e.g. cancelled) is intentionally hidden, not "unplaced".
    private var unplacedTasks: [Concept] {
        let declared = Set(bundle.schema.taskStatuses.map(\.id))
        return scopedTasks
            .filter { task in
                guard let s = task.status, !s.isEmpty else { return true }
                return !declared.contains(s)
            }
            .sorted { $0.title < $1.title }
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
}

struct ColumnView: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = .primary
    let tasks: [Concept]
    let bundle: OKFBundle

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Pinned header — stays put while the cards scroll under it.
            HStack(spacing: 5) {
                if let systemImage {
                    Image(systemName: systemImage).foregroundStyle(tint)
                }
                Text(title).font(.headline).foregroundStyle(tint)
                Spacer()
                Text("\(tasks.count)").font(.caption).foregroundStyle(.secondary)
            }

            // Each column scrolls independently so a long column doesn't push the board
            // past the window. `LazyVStack` keeps large columns cheap.
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(tasks) { task in
                        NavigationLink(value: task.id) {
                            TaskCard(task: task, bundle: bundle)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        // Fixed column width; fill the available height (second frame) so the inner
        // ScrollView has a bounded frame to scroll in.
        .frame(width: 240)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct TaskCard: View {
    let task: Concept
    let bundle: OKFBundle

    private var hasOpenBlockers: Bool {
        let done = bundle.schema.taskStatus(for: .done)
        return task.blockedBy.contains { bundle.concept($0)?.status != done }
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
