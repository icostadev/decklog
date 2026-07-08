import SwiftUI
import OKFKit

struct ContentView: View {
    @EnvironmentObject var store: BundleStore
    @State private var selectedProjectID: String?  // nil = all tasks
    @State private var selectedTaskID: String?

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedProjectID: $selectedProjectID)
        } content: {
            if let bundle = store.bundle {
                BoardView(
                    bundle: bundle,
                    projectID: selectedProjectID,
                    selectedTaskID: $selectedTaskID
                )
            } else {
                EmptyBundleView()
            }
        } detail: {
            if let bundle = store.bundle,
               let id = selectedTaskID,
               let task = bundle.concept(id) {
                TaskDetailView(task: task, bundle: bundle)
            } else {
                Text("Select a task")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { store.openBundle() } label: {
                    Label("Open Bundle", systemImage: "folder")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { store.reload() } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .disabled(store.bundle == nil)
            }
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var store: BundleStore
    @Binding var selectedProjectID: String?

    private var projects: [Concept] {
        store.bundle?.concepts(ofKind: .project) ?? []
    }

    var body: some View {
        List(selection: $selectedProjectID) {
            Section("Scope") {
                Label("All tasks", systemImage: "tray.full")
                    .tag(String?.none)
                ForEach(projects) { project in
                    Label(project.title, systemImage: "folder")
                        .tag(Optional(project.id))
                }
            }

            if !store.issues.isEmpty {
                Section("Validation") {
                    ForEach(Array(store.issues.enumerated()), id: \.offset) { _, issue in
                        Label(
                            "\(issue.conceptID): \(issue.message)",
                            systemImage: issue.severity == .error
                                ? "xmark.octagon" : "exclamationmark.triangle"
                        )
                        .font(.caption)
                        .foregroundStyle(issue.severity == .error ? .red : .orange)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("OKF-PM")
    }
}

struct EmptyBundleView: View {
    @EnvironmentObject var store: BundleStore

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No bundle open").font(.headline)
            if let error = store.errorMessage {
                Text(error).foregroundStyle(.red).font(.caption)
            }
            Button("Open Bundle…") { store.openBundle() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
