import AppKit
import WebKit

@MainActor
final class ViewerWindowController: NSWindowController {
    private let fileURL: URL
    private var webView: WKWebView?
    private var renderer: DocumentRenderer?
    private var fileWatcher: FileWatcher?
    private var pendingScrollPosition: Double?
    private var hasBegunLoading = false

    init(fileURL: URL) {
        self.fileURL = fileURL

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = fileURL.lastPathComponent
        window.contentView = Self.makeLoadingView(filename: fileURL.lastPathComponent)
        window.center()
        window.setFrameAutosaveName("mdview.viewer")

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func beginLoading() {
        guard !hasBegunLoading else { return }
        hasBegunLoading = true

        // Give AppKit a chance to put the lightweight native window on screen
        // before WebKit starts its helper processes.
        DispatchQueue.main.async { [weak self] in
            self?.installWebViewAndLoadDocument()
        }
    }

    func reload() {
        guard webView != nil else { return }
        _ = loadFile(preservingScrollPosition: true)
    }

    func zoomIn() {
        guard let webView else { return }
        webView.pageZoom = min(webView.pageZoom * 1.1, 3.0)
    }

    func zoomOut() {
        guard let webView else { return }
        webView.pageZoom = max(webView.pageZoom / 1.1, 0.5)
    }

    func resetZoom() {
        webView?.pageZoom = 1.0
    }

    private func installWebViewAndLoadDocument() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self

        do {
            renderer = try DocumentRenderer()
        } catch {
            presentLoadError(error, closesWindow: true)
            return
        }

        self.webView = webView
        window?.contentView = webView
        window?.initialFirstResponder = webView
        window?.makeFirstResponder(webView)

        guard loadFile(preservingScrollPosition: false) else { return }
        startWatchingFile()
    }

    @discardableResult
    private func loadFile(preservingScrollPosition: Bool) -> Bool {
        do {
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            display(markdown: contents, preservingScrollPosition: preservingScrollPosition)
            return true
        } catch {
            presentLoadError(error, closesWindow: fileWatcher == nil)
            return false
        }
    }

    private func display(markdown: String, preservingScrollPosition: Bool) {
        guard let webView, let renderer else { return }

        let load: (Double?) -> Void = { [weak self] scrollPosition in
            guard let self, let webView = self.webView else { return }
            pendingScrollPosition = scrollPosition
            let html = renderer.render(markdown: markdown)
            webView.loadHTMLString(html, baseURL: fileURL.deletingLastPathComponent())
        }

        guard preservingScrollPosition else {
            load(nil)
            return
        }

        webView.evaluateJavaScript("window.scrollY") { value, _ in
            load((value as? NSNumber)?.doubleValue)
        }
    }

    private func startWatchingFile() {
        do {
            fileWatcher = try FileWatcher(fileURL: fileURL) { [weak self] result in
                guard let self else { return }
                switch result {
                case let .success(markdown):
                    self.display(markdown: markdown, preservingScrollPosition: true)
                case let .failure(error):
                    self.presentLoadError(error, closesWindow: false)
                }
            }
        } catch {
            NSLog("mdview: automatic reload unavailable: %@", error.localizedDescription)
        }
    }

    private func presentLoadError(_ error: Error, closesWindow: Bool) {
        let alert = NSAlert(error: error)
        alert.messageText = "Could not open \(fileURL.lastPathComponent)"

        if closesWindow {
            alert.runModal()
            close()
        } else if let window, window.attachedSheet == nil {
            alert.beginSheetModal(for: window)
        }
    }

    private static func makeLoadingView(filename: String) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor

        let label = NSTextField(labelWithString: "Opening \(filename)…")
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        return container
    }
}

extension ViewerWindowController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard navigationAction.navigationType == .linkActivated,
              let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        switch LinkPolicy.disposition(for: url) {
        case .allowInViewer:
            decisionHandler(.allow)
        case .openExternally:
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        case .deny:
            NSSound.beep()
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let scrollPosition = pendingScrollPosition else { return }
        pendingScrollPosition = nil
        webView.evaluateJavaScript("window.scrollTo(0, \(scrollPosition))")
    }
}
