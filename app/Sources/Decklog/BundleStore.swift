import Foundation
import AppKit
import OKFKit

/// Loads and holds the current bundle. Read-only for Iteration 1 (no writes).
/// Set `DECKLOG_BUNDLE=/path/to/bundle` to auto-open a bundle on launch (dev convenience).
@MainActor
final class BundleStore: ObservableObject {
    @Published var bundle: OKFBundle?
    @Published var issues: [ValidationIssue] = []
    @Published var errorMessage: String?
    @Published var agent: PMAgentSession?
    /// Executor runs keyed by task id (the most recent run for each task).
    @Published var executors: [String: ExecutorSession] = [:]

    init() {
        if let path = ProcessInfo.processInfo.environment["DECKLOG_BUNDLE"] {
            load(url: URL(fileURLWithPath: path))
        }
    }

    func load(url: URL) {
        do {
            let loaded = try OKFBundle.load(at: url)
            bundle = loaded
            issues = loaded.validate()
            errorMessage = nil

            let session = PMAgentSession(bundleURL: url)
            session.onTurnComplete = { [weak self] commitMessage in
                self?.commitAndReload(message: commitMessage)
            }
            agent = session
        } catch {
            errorMessage = "\(error)"
        }
    }

    /// After a PM agent turn: commit the edits (only if the bundle is its own repo root)
    /// and reload from disk so the board reflects the changes. Keeps the chat session.
    private func commitAndReload(message: String) {
        guard let url = bundle?.rootURL else { return }
        if BundleGit.isRepositoryRoot(at: url) {
            _ = try? BundleGit.commitAll(at: url, message: message)
        }
        if let reloaded = try? OKFBundle.load(at: url) {
            bundle = reloaded
            issues = reloaded.validate()
        }
    }

    // MARK: Task execution (Iteration 3)

    /// Dispatch a task to an executor: resolve its project's repo, run it in a worktree,
    /// and let the session advance the task's lifecycle in the bundle. No-op if the
    /// dispatch gate fails or the project has no local repo.
    func dispatch(taskID: String) {
        guard let bundle,
              let task = bundle.concept(taskID),
              bundle.dispatchDecision(forTask: taskID).canDispatch,
              executors[taskID]?.phase != .running,
              let project = bundle.project(forTask: taskID),
              let repoURL = bundle.repoURL(forProject: project.id) else { return }

        let session = ExecutorSession(task: task, bundle: bundle, repoURL: repoURL)
        session.onStatusChange = { [weak self] status in
            self?.applyTaskChange(taskID) { $0.set(status: status) }
        }
        session.onArtifact = { [weak self] branch in
            self?.applyTaskChange(taskID) { concept in
                var artifacts = concept.artifacts
                if !artifacts.contains(branch) { artifacts.append(branch) }
                concept.set(artifacts: artifacts)
            }
        }
        executors[taskID] = session
        session.start()
    }

    /// Apply a mutation to a task concept: write it back, commit the bundle (if it's a
    /// repo root), and reload so the board reflects it.
    private func applyTaskChange(_ taskID: String, _ mutate: (inout Concept) -> Void) {
        guard let bundle, var concept = bundle.concept(taskID) else { return }
        mutate(&concept)
        try? bundle.write(concept)
        if BundleGit.isRepositoryRoot(at: bundle.rootURL) {
            _ = try? BundleGit.commitAll(
                at: bundle.rootURL,
                message: "decklog: \(taskID) → \(concept.status ?? "updated")")
        }
        if let reloaded = try? OKFBundle.load(at: bundle.rootURL) {
            self.bundle = reloaded
            self.issues = reloaded.validate()
        }
    }

    func openBundle() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Bundle"
        if panel.runModal() == .OK, let url = panel.url {
            load(url: url)
        }
    }

    func reload() {
        if let url = bundle?.rootURL { load(url: url) }
    }
}
