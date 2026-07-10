import SwiftUI
import AppKit
import OKFKit

struct ContentView: View {
    @EnvironmentObject var store: BundleStore
    @State private var selectedScope: String = SidebarView.allScope
    @State private var issuesExpanded = false
    @State private var showChat = true
    @State private var showRuns = false
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
        .sheet(isPresented: errorAlertPresented) {
            ErrorSheet(message: store.errorMessage ?? "") { store.errorMessage = nil }
        }
        // Tolerant load keeps a degraded bundle open; surface quarantined files immediately
        // instead of leaving them hidden behind the collapsed validation panel.
        .onChange(of: store.loadErrorCount) { count in
            if count > 0 { issuesExpanded = true }
        }
    }

    /// Drives the error sheet off `store.errorMessage`; clearing it dismisses the sheet.
    private var errorAlertPresented: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { presented in if !presented { store.errorMessage = nil } }
        )
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
            ToolbarItem(placement: .primaryAction) {
                Button { showRuns.toggle() } label: {
                    Label("Runs", systemImage: "play.circle")
                }
                .disabled(store.executors.isEmpty)
                .popover(isPresented: $showRuns, arrowEdge: .bottom) {
                    RunsView().environmentObject(store)
                }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if let bundle = store.bundle {
            VStack(spacing: 0) {
                if !bundle.loadErrors.isEmpty {
                    LoadErrorBanner(count: bundle.loadErrors.count) {
                        withAnimation(.easeInOut(duration: 0.15)) { issuesExpanded = true }
                    }
                }
                if selectedScope == SidebarView.planScope {
                    PlanView(bundle: bundle)
                } else if selectedScope != SidebarView.allScope,
                          let scoped = bundle.concept(selectedScope), scoped.kind == .objective {
                    ObjectiveView(objective: scoped, bundle: bundle)
                } else {
                    BoardView(
                        bundle: bundle,
                        projectID: selectedScope == SidebarView.allScope ? nil : selectedScope
                    )
                }
            }
        } else {
            EmptyBundleView()
        }
    }
}

/// A non-blocking strip shown above the board when tolerant load quarantined files.
/// The bundle still opens; this makes the skipped files visible (and points at the panel)
/// instead of leaving the board looking mysteriously empty.
struct LoadErrorBanner: View {
    let count: Int
    let onShowDetails: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(count == 1
                 ? "1 file couldn't be read and was skipped."
                 : "\(count) files couldn't be read and were skipped.")
                .font(.callout)
            Spacer(minLength: 8)
            Button("Show details", action: onShowDetails)
                .buttonStyle(.link)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.12))
        .overlay(alignment: .bottom) { Divider() }
    }
}

struct SidebarView: View {
    /// Sentinel value for the "All tasks" scope.
    static let allScope = "__all_tasks__"
    /// Sentinel value for the Plan (dependency-sequence) scope.
    static let planScope = "__plan__"

    @EnvironmentObject var store: BundleStore
    @Binding var selectedScope: String

    private var projects: [Concept] {
        store.bundle?.concepts(ofKind: .project) ?? []
    }

    private var objectives: [Concept] {
        store.bundle?.objectives() ?? []
    }

    /// A compact "done/total" progress label for an objective's rollup.
    private func objectiveSubtitle(for objective: Concept) -> String {
        guard let rollup = store.bundle?.rollup(forObjective: objective.id) else { return "" }
        return rollup.total == 0 ? "no tasks yet" : "\(rollup.doneCount)/\(rollup.total) done"
    }

    /// A short, friendly repo label: basename without a trailing `.git`.
    static func shortRepoName(_ repo: String) -> String {
        var s = repo
        if s.hasSuffix(".git") { s = String(s.dropLast(4)) }
        if let idx = s.lastIndex(where: { $0 == "/" || $0 == ":" }) {
            s = String(s[s.index(after: idx)...])
        }
        return s.isEmpty ? repo : s
    }

    /// Sidebar label for a project's repo, resolving relative paths (e.g. `..`) against
    /// the bundle root so they show a real directory name.
    private func repoLabel(for project: Concept) -> String {
        guard let repo = project.repo else { return "No repo linked" }
        if repo.hasPrefix("."), let root = store.bundle?.rootURL {
            return URL(fileURLWithPath: repo, relativeTo: root)
                .standardizedFileURL.lastPathComponent
        }
        return Self.shortRepoName(repo)
    }

    var body: some View {
        List {
            Section("Scope") {
                ScopeRow(title: "All tasks", systemImage: "tray.full",
                         isSelected: selectedScope == Self.allScope) {
                    selectedScope = Self.allScope
                }
                ScopeRow(title: "Plan", systemImage: "list.number",
                         isSelected: selectedScope == Self.planScope) {
                    selectedScope = Self.planScope
                }
            }
            Section("Projects") {
                ForEach(projects) { project in
                    ScopeRow(
                        title: project.title,
                        systemImage: "folder",
                        subtitle: repoLabel(for: project),
                        subtitleIcon: project.repo == nil ? "questionmark.circle" : "arrow.triangle.branch",
                        isSelected: selectedScope == project.id
                    ) {
                        selectedScope = project.id
                    }
                    .help(project.repo ?? "No repository linked")
                }
            }
            if !objectives.isEmpty {
                Section("Objectives") {
                    ForEach(objectives) { objective in
                        ScopeRow(
                            title: objective.title,
                            systemImage: "target",
                            subtitle: objectiveSubtitle(for: objective),
                            subtitleIcon: "chart.bar.fill",
                            isSelected: selectedScope == objective.id
                        ) {
                            selectedScope = objective.id
                        }
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
    var subtitle: String? = nil
    var subtitleIcon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                    if let subtitle {
                        HStack(spacing: 3) {
                            if let subtitleIcon { Image(systemName: subtitleIcon) }
                            Text(subtitle).lineLimit(1).truncationMode(.middle)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
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
            Button("Open Bundle…") { store.openBundle() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A resizable error dialog with a scrollable, selectable message and a Copy button that
/// does not dismiss (unlike a system alert).
struct ErrorSheet: View {
    let message: String
    let onClose: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Couldn't open bundle", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            ScrollView {
                Text(message)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .frame(minHeight: 180)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .textBackgroundColor)))

            HStack {
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message, forType: .string)
                    copied = true
                } label: {
                    Label(copied ? "Copied" : "Copy Details",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                Spacer()
                Button("Close") { onClose() }.keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(minWidth: 480, minHeight: 340)
    }
}
