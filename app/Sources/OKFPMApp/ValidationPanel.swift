import SwiftUI
import AppKit
import OKFKit

/// A bottom status bar summarizing validation issues, expandable into a scrollable
/// list (Xcode-style). Advisory only — nothing here mutates the bundle.
struct ValidationPanel: View {
    let issues: [ValidationIssue]
    @Binding var isExpanded: Bool

    @State private var justCopied = false

    private var errorCount: Int { issues.filter { $0.severity == .error }.count }
    private var warningCount: Int { issues.filter { $0.severity == .warning }.count }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            if isExpanded && !issues.isEmpty {
                issueList
                Divider()
            }

            statusBar
        }
        .background(.bar)
    }

    private var issueList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: issue.severity == .error
                              ? "xmark.octagon.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(issue.severity == .error ? .red : .orange)
                        Text(issue.conceptID).fontWeight(.medium)
                        Text(issue.message).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                    .font(.caption)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 3)
                }
            }
            .padding(.vertical, 6)
        }
        .frame(maxHeight: 180)
        .background(Color(nsColor: .textBackgroundColor))
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            summary
            Spacer()
            if !issues.isEmpty {
                Button(action: copyAll) {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(justCopied ? .green : .secondary)
                }
                .buttonStyle(.plain)
                .help("Copy all issues to clipboard")

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { isExpanded.toggle() }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help(isExpanded ? "Collapse" : "Expand")
            }
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
    }

    private func copyAll() {
        let text = issues
            .map { "[\($0.severity.rawValue)] \($0.conceptID): \($0.message)" }
            .joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        justCopied = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            justCopied = false
        }
    }

    @ViewBuilder
    private var summary: some View {
        if issues.isEmpty {
            Label("No validation issues", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        } else {
            HStack(spacing: 14) {
                if errorCount > 0 {
                    Label("\(errorCount)", systemImage: "xmark.octagon.fill")
                        .foregroundStyle(.red)
                }
                Label("\(warningCount)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            .font(.caption)
        }
    }
}
