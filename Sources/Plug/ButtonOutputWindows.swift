import AppKit
import SwiftUI

/// A small window showing what a button's command printed, or Claude's
/// reply. One window, reused for each new result.
@MainActor
final class ButtonOutputWindows {
    private var window: NSWindow?

    func show(title: String, text: String) {
        let content = NSHostingController(rootView: ButtonOutputView(text: text))
        let window = window ?? NSWindow(contentViewController: content)
        window.contentViewController = content
        window.title = title
        window.styleMask.insert([.resizable, .closable, .titled])
        window.isReleasedWhenClosed = false
        if self.window == nil {
            window.setContentSize(NSSize(width: 460, height: 320))
            window.center()
            self.window = window
        }
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }
}

private struct ButtonOutputView: View {
    let text: String

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ScrollView {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
            }
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            Button("Copy") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
        }
        .padding(14)
        .frame(minWidth: 320, minHeight: 200)
    }
}
