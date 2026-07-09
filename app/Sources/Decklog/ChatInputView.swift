import SwiftUI
import AppKit

/// Multiline chat input backed by NSTextView. **Enter sends**, **Shift+Enter inserts a
/// newline**. Reports its laid-out content height via `height` so the container can grow
/// the field from one line upward; the container caps the height and this view scrolls.
struct ChatInputView: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    var isEnabled: Bool
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.drawsBackground = false
        textView.allowsUndo = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 0, height: CGFloat.greatestFiniteMagnitude
        )

        let scroll = NSScrollView()
        scroll.documentView = textView
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.scrollerStyle = .overlay // hidden until content overflows and you scroll
        scroll.drawsBackground = false
        scroll.borderType = .bezelBorder

        context.coordinator.textView = textView
        DispatchQueue.main.async { context.coordinator.recalculateHeight() }
        return scroll
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        textView.isEditable = isEnabled
        textView.textColor = isEnabled ? .labelColor : .disabledControlTextColor
        DispatchQueue.main.async { context.coordinator.recalculateHeight() }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: ChatInputView
        weak var textView: NSTextView?

        init(_ parent: ChatInputView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            recalculateHeight()
        }

        /// Laid-out content height (one line minimum), published to the SwiftUI binding.
        func recalculateHeight() {
            guard let textView,
                  let layoutManager = textView.layoutManager,
                  let container = textView.textContainer else { return }
            layoutManager.ensureLayout(for: container)
            let used = layoutManager.usedRect(for: container).height
            let total = used + textView.textContainerInset.height * 2
            let oneLine = (textView.font?.boundingRectForFont.height ?? 16)
                + textView.textContainerInset.height * 2
            let clamped = max(total, oneLine)
            if abs(clamped - parent.height) > 0.5 {
                parent.height = clamped
            }
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }
            let shiftHeld = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
            if shiftHeld {
                textView.insertNewlineIgnoringFieldEditor(nil) // Shift+Enter → line break
            } else {
                parent.onSubmit()                              // Enter → send
            }
            return true
        }
    }
}
