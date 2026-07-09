import SwiftUI

/// Popover listing this session's executor runs with their phase; in-flight runs can be
/// cancelled. Multiple tasks can run concurrently (each in its own worktree).
struct RunsView: View {
    @EnvironmentObject var store: BundleStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Runs").font(.headline)
            if store.runs.isEmpty {
                Text("No runs yet.").font(.caption).foregroundStyle(.secondary)
            } else {
                ForEach(store.runs, id: \.taskID) { RunRow(session: $0) }
            }
        }
        .padding()
        .frame(minWidth: 300)
    }
}

private struct RunRow: View {
    @ObservedObject var session: ExecutorSession

    private var isActive: Bool {
        [.preparing, .running, .committing].contains(session.phase)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(isActive ? Color.accentColor : .secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(session.taskTitle).font(.callout).lineLimit(1)
                Text(session.phase.rawValue).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            if isActive {
                Button("Cancel") { session.cancel() }.font(.caption)
            }
        }
    }

    private var icon: String {
        switch session.phase {
        case .review: return "checkmark.circle"
        case .failed: return "xmark.octagon"
        case .cancelled: return "slash.circle"
        default: return "circle.dotted"
        }
    }
}
