import AppKit
import WebKit

@MainActor
final class ViewerWindowController: NSWindowController {
    private static let sharedDataStore = WKWebsiteDataStore.nonPersistent()
    private static let sharedRenderer = Result { try DocumentRenderer() }

    private let fileURL: URL
    private var webView: WKWebView?
    private var renderer: DocumentRenderer?
    private var fileWatcher: FileWatcher?
    private var pendingScrollPosition: Double?
    private var findBar: NSView?
    private var findBarHeightConstraint: NSLayoutConstraint?
    private var findField: NSSearchField?
    private var findStatusLabel: NSTextField?
    private var findGeneration = 0
    private var hasBegunLoading = false

    init(fileURL: URL) {
        self.fileURL = fileURL

        let window = ViewerWindow(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = fileURL.lastPathComponent
        window.tabbingMode = .disallowed
        window.miniwindowImage = ApplicationIcon.image()
        window.contentView = Self.makeLoadingView(filename: fileURL.lastPathComponent)
        window.center()
        window.setFrameAutosaveName("mdview.viewer")

        super.init(window: window)

        let sidebarButton = NSButton(
            image: NSImage(systemSymbolName: "sidebar.left", accessibilityDescription: "Table of Contents")!,
            target: self,
            action: #selector(toggleTableOfContents(_:))
        )
        sidebarButton.bezelStyle = .toolbar
        sidebarButton.toolTip = "Show Table of Contents"
        sidebarButton.setAccessibilityLabel("Show table of contents")
        let sidebarAccessory = NSTitlebarAccessoryViewController()
        sidebarAccessory.layoutAttribute = .left
        sidebarAccessory.view = sidebarButton
        window.addTitlebarAccessoryViewController(sidebarAccessory)
        window.commandKeyHandler = { [weak self] event in
            self?.handleCommandKeyEquivalent(event) ?? false
        }
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

    private func handleCommandKeyEquivalent(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers == [.command] || modifiers == [.command, .shift],
              let character = event.charactersIgnoringModifiers?.lowercased() else {
            return false
        }

        switch (character, modifiers) {
        case ("f", [.command]):
            showFind()
        case ("g", [.command]):
            findNext()
        case ("g", [.command, .shift]):
            findPrevious()
        case ("`", [.command]):
            selectNextWindow()
        case ("`", [.command, .shift]):
            selectPreviousWindow()
        default:
            return false
        }
        return true
    }

    func showFind() {
        guard let window, let findBar, let findBarHeightConstraint, let findField else { return }
        findBar.isHidden = false
        findBarHeightConstraint.constant = 42
        window.contentView?.layoutSubtreeIfNeeded()
        window.makeFirstResponder(findField)
        findField.selectText(nil)
    }

    func findNext() {
        find(backwards: false)
    }

    func findPrevious() {
        find(backwards: true)
    }

    func selectNextWindow() {
        selectWindow(backwards: false)
    }

    func selectPreviousWindow() {
        selectWindow(backwards: true)
    }

    private func selectWindow(backwards: Bool) {
        // `orderedWindows` changes whenever a window becomes key, which makes
        // it alternate between two windows. `windows` preserves AppKit's
        // stable creation order for a predictable full cycle.
        let windows = NSApplication.shared.windows.compactMap { $0 as? ViewerWindow }
        guard windows.count > 1 else { return }

        let currentWindow = (NSApplication.shared.keyWindow as? ViewerWindow) ?? (window as? ViewerWindow)
        guard let currentWindow else { return }
        let currentIndex = windows.firstIndex(of: currentWindow) ?? 0
        let offset = backwards ? -1 : 1
        let nextIndex = (currentIndex + offset + windows.count) % windows.count
        windows[nextIndex].makeKeyAndOrderFront(nil)
    }

    private func installWebViewAndLoadDocument() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = Self.sharedDataStore
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = false

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self

        switch Self.sharedRenderer {
        case let .success(renderer):
            self.renderer = renderer
        case let .failure(error):
            presentLoadError(error, closesWindow: true)
            return
        }

        self.webView = webView
        installContentView(containing: webView)
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

    private func installContentView(containing webView: WKWebView) {
        guard let window else { return }

        let container = NSView()
        let findBar = NSVisualEffectView()
        findBar.material = .headerView
        findBar.blendingMode = .withinWindow
        findBar.state = .active
        findBar.isHidden = true

        let findField = NSSearchField()
        findField.placeholderString = "Find"
        findField.delegate = self
        findField.target = self
        findField.action = #selector(findFieldDidSubmit(_:))
        findField.setAccessibilityLabel("Find in document")

        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .right
        statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        statusLabel.setAccessibilityLabel("Find result")

        let previousButton = NSButton(
            title: "Previous",
            target: self,
            action: #selector(findPreviousButtonPressed(_:))
        )
        previousButton.toolTip = "Find Previous (Shift-Command-G)"
        previousButton.setAccessibilityLabel("Find previous")

        let nextButton = NSButton(
            title: "Next",
            target: self,
            action: #selector(findNextButtonPressed(_:))
        )
        nextButton.toolTip = "Find Next (Command-G)"
        nextButton.setAccessibilityLabel("Find next")

        let doneButton = NSButton(
            title: "Done",
            target: self,
            action: #selector(closeFindBar(_:))
        )
        doneButton.keyEquivalent = "\u{1b}"
        doneButton.setAccessibilityLabel("Close find bar")

        let controls = NSStackView(views: [findField, statusLabel, previousButton, nextButton, doneButton])
        controls.orientation = .horizontal
        controls.alignment = .centerY
        controls.spacing = 8

        [webView, findBar, controls].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        container.addSubview(webView)
        container.addSubview(findBar)
        findBar.addSubview(controls)

        let findBarHeightConstraint = findBar.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            findBar.topAnchor.constraint(equalTo: container.topAnchor),
            findBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            findBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            findBarHeightConstraint,

            controls.centerYAnchor.constraint(equalTo: findBar.centerYAnchor),
            controls.trailingAnchor.constraint(equalTo: findBar.trailingAnchor, constant: -12),
            controls.leadingAnchor.constraint(greaterThanOrEqualTo: findBar.leadingAnchor, constant: 12),
            findField.widthAnchor.constraint(equalToConstant: 240),

            webView.topAnchor.constraint(equalTo: findBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        self.findBar = findBar
        self.findBarHeightConstraint = findBarHeightConstraint
        self.findField = findField
        findStatusLabel = statusLabel
        window.contentView = container
    }

    @objc private func toggleTableOfContents(_ sender: Any?) {
        webView?.evaluateJavaScript("window.mdviewToggleSidebar?.()")
    }

    private func find(backwards: Bool) {
        guard let webView, let findField else { return }
        let query = findField.stringValue
        guard !query.isEmpty else {
            showFind()
            return
        }

        let configuration = WKFindConfiguration()
        configuration.backwards = backwards
        configuration.caseSensitive = false
        configuration.wraps = true

        findGeneration += 1
        let generation = findGeneration
        webView.find(query, configuration: configuration) { [weak self] result in
            guard let self,
                  generation == self.findGeneration,
                  query == self.findField?.stringValue else { return }
            self.findStatusLabel?.stringValue = result.matchFound ? "" : "No matches"
        }
    }

    private func clearFindSelection() {
        findGeneration += 1
        findStatusLabel?.stringValue = ""
        webView?.evaluateJavaScript("window.getSelection().removeAllRanges()")
    }

    @objc private func findFieldDidSubmit(_ sender: NSSearchField) {
        findNext()
    }

    @objc private func findNextButtonPressed(_ sender: Any?) {
        findNext()
    }

    @objc private func findPreviousButtonPressed(_ sender: Any?) {
        findPrevious()
    }

    @objc private func closeFindBar(_ sender: Any?) {
        guard let window, let findBar, let findBarHeightConstraint else { return }
        findBarHeightConstraint.constant = 0
        findBar.isHidden = true
        window.makeFirstResponder(webView)
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
        case .openExternally:
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        case .deny:
            NSSound.beep()
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let scrollPosition = pendingScrollPosition {
            pendingScrollPosition = nil
            webView.evaluateJavaScript("window.scrollTo(0, \(scrollPosition))")
        }

        if findBar?.isHidden == false, findField?.stringValue.isEmpty == false {
            find(backwards: false)
        }
    }
}

extension ViewerWindowController: NSSearchFieldDelegate {
    func controlTextDidChange(_ notification: Notification) {
        guard let findField else { return }
        if findField.stringValue.isEmpty {
            clearFindSelection()
        } else {
            find(backwards: false)
        }
    }

    func control(
        _ control: NSControl,
        textView: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        guard commandSelector == #selector(NSResponder.cancelOperation(_:)) else { return false }
        closeFindBar(nil)
        return true
    }
}
