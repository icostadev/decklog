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
