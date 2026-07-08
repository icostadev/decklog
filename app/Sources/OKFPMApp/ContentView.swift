import SwiftUI
import OKFKit

struct ContentView: View {
    @EnvironmentObject var store: BundleStore
    @State private var selectedProjectID: String?  // nil = all tasks
    @State private var issuesExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            navigationArea
            if store.bundle != nil {
                ValidationPanel(issues: store.issues, isExpanded: $issuesExpanded)
            }
        }
    }

    private var navigationArea: some View {
        NavigationSplitView {
            SidebarView(selectedProjectID: $selectedProjectID)
        } detail: {
            NavigationStack {
                mainContent
                    // Tapping a task card pushes its full-page view (back returns to the board).
                    .navigationDestination(for: String.self) { taskID in
                        if let bundle = store.bundle, let task = bundle.concept(taskID) {
                            TaskDetailView(task: task, bundle: bundle)
                        } else {
                            Text("Task not found")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
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

    @ViewBuilder
    private var mainContent: some View {
        if let bundle = store.bundle {
            BoardView(bundle: bundle, projectID: selectedProjectID)
        } else {
            EmptyBundleView()
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
