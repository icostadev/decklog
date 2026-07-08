import Foundation
import AppKit
import OKFKit

/// Loads and holds the current bundle. Read-only for Iteration 1 (no writes).
/// Set `OKFPM_BUNDLE=/path/to/bundle` to auto-open a bundle on launch (dev convenience).
@MainActor
final class BundleStore: ObservableObject {
    @Published var bundle: OKFBundle?
    @Published var issues: [ValidationIssue] = []
    @Published var errorMessage: String?

    init() {
        if let path = ProcessInfo.processInfo.environment["OKFPM_BUNDLE"] {
            load(url: URL(fileURLWithPath: path))
        }
    }

    func load(url: URL) {
        do {
            let loaded = try OKFBundle.load(at: url)
            bundle = loaded
            issues = loaded.validate()
            errorMessage = nil
        } catch {
            errorMessage = "\(error)"
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
