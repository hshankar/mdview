import AppKit
import WebKit

@MainActor
final class ViewerWindowController: NSWindowController {
    private let fileURL: URL
    private let webView: WKWebView
    private let renderer: DocumentRenderer

    init(fileURL: URL) {
        self.fileURL = fileURL

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        webView = WKWebView(frame: .zero, configuration: configuration)

        do {
            renderer = try DocumentRenderer()
        } catch {
            fatalError("Could not initialize the document renderer: \(error.localizedDescription)")
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = fileURL.lastPathComponent
        window.contentView = webView
        window.center()
        window.setFrameAutosaveName("mdview.viewer")

        super.init(window: window)
        loadFile()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadFile() {
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            let html = renderer.render(markdown: contents)
            webView.loadHTMLString(html, baseURL: fileURL.deletingLastPathComponent())
        } catch {
            presentLoadError(error)
        }
    }

    private func presentLoadError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = "Could not open \(fileURL.lastPathComponent)"
        alert.runModal()
        close()
    }
}
