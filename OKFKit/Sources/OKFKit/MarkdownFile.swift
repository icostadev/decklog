import Foundation

/// Splits a raw "markdown with YAML frontmatter" file into its frontmatter text
/// and body. OKF frontmatter is a leading block delimited by `---` fence lines.
public struct MarkdownFile {
    /// The YAML text between the fences, or `nil` if the file has no frontmatter.
    /// An empty (but present) frontmatter block yields `""`.
    public var frontmatterText: String?
    /// Everything after the closing fence (a single leading newline is trimmed).
    public var body: String

    public init(raw: String) {
        let normalized = raw.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.components(separatedBy: "\n")

        // Must open with a `---` fence on the very first line.
        guard lines.first == "---" else {
            self.frontmatterText = nil
            self.body = normalized
            return
        }

        // Find the closing `---` fence.
        var closeIndex: Int?
        if lines.count > 1 {
            for i in 1..<lines.count where lines[i] == "---" {
                closeIndex = i
                break
            }
        }
        guard let close = closeIndex else {
            // No closing fence — treat the whole thing as body (malformed frontmatter).
            self.frontmatterText = nil
            self.body = normalized
            return
        }

        self.frontmatterText = lines[1..<close].joined(separator: "\n")

        var body = lines[(close + 1)...].joined(separator: "\n")
        if body.hasPrefix("\n") { body.removeFirst() }
        self.body = body
    }
}
