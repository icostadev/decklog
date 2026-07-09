import SwiftUI
import OKFKit

struct ContentView: View {
    @EnvironmentObject var store: BundleStore
    @State private var selectedScope: String = SidebarView.allScope
    @State private var issuesExpanded = false
    @State private var showChat = true
    @State private var navPath = NavigationPath()

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                navigationArea
                    .frame(minWidth: 480)
                if showChat, let agent = store.agent {
                    ChatPanel(session: agent)
                        .frame(minWidth: 280, idealWidth: 380, maxWidth: 700)
                }
            }
            if store.bundle != nil {
                ValidationPanel(issues: store.issues, isExpanded: $issuesExpanded)
            }
        }
    }

    private var navigationArea: some View {
        NavigationSplitView {
            SidebarView(selectedScope: $selectedScope)
        } detail: {
            NavigationStack(path: $navPath) {
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
            // Changing scope returns to the board (pops any pushed task detail).
            .onChange(of: selectedScope) { _ in navPath = NavigationPath() }
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
            ToolbarItem(placement: .primaryAction) {
                Button { showChat.toggle() } label: {
                    Label("PM agent", systemImage: "bubble.left.and.text.bubble.right")
                }
                .disabled(store.agent == nil)
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if let bundle = store.bundle {
            BoardView(
                bundle: bundle,
                projectID: selectedScope == SidebarView.allScope ? nil : selectedScope
            )
        } else {
            EmptyBundleView()
        }
    }
}

struct SidebarView: View {
    /// Sentinel value for the "All tasks" scope.
    static let allScope = "__all_tasks__"

    @EnvironmentObject var store: BundleStore
    @Binding var selectedScope: String

    private var projects: [Concept] {
        store.bundle?.concepts(ofKind: .project) ?? []
    }

    var body: some View {
        List {
            Section("Scope") {
                ScopeRow(title: "All tasks", systemImage: "tray.full",
                         isSelected: selectedScope == Self.allScope) {
                    selectedScope = Self.allScope
                }
                ForEach(projects) { project in
                    ScopeRow(title: project.title, systemImage: "folder",
                             isSelected: selectedScope == project.id) {
                        selectedScope = project.id
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Decklog")
    }
}

/// A sidebar scope row: an explicit button (reliable click handling) with manual
/// selection highlight, avoiding `List(selection:)` quirks inside a NavigationSplitView.
private struct ScopeRow: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            isSelected ? Color.accentColor.opacity(0.20) : Color.clear
        )
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
