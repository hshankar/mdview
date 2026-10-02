import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let initialFileURL: URL
    private let idleTimeout: TimeInterval
    private var viewerWindowControllers: [ObjectIdentifier: ViewerWindowController] = [:]
    private var messageServer: ViewerMessageServer?
    private var idleTimer: Timer?

    init(fileURL: URL, idleTimeout: TimeInterval = 5 * 60) {
        initialFileURL = fileURL
        self.idleTimeout = idleTimeout
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        ApplicationIcon.install(on: NSApplication.shared)

        guard claimServerPort() else {
            NSApplication.shared.terminate(nil)
            return
        }

        ApplicationMenu.install(target: self)
        openDocument(at: initialFileURL)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        idleTimer?.invalidate()
        messageServer = nil
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        viewerWindowControllers.removeValue(forKey: ObjectIdentifier(window))

        if viewerWindowControllers.isEmpty {
            scheduleIdleTermination()
        }
    }

    @objc func reloadDocument(_ sender: Any?) {
        activeViewer?.reload()
    }

    @objc func zoomIn(_ sender: Any?) {
        activeViewer?.zoomIn()
    }

    @objc func zoomOut(_ sender: Any?) {
        activeViewer?.zoomOut()
    }

    @objc func resetZoom(_ sender: Any?) {
        activeViewer?.resetZoom()
    }

    @objc func showFind(_ sender: Any?) {
        activeViewer?.showFind()
    }

    @objc func findNext(_ sender: Any?) {
        activeViewer?.findNext()
    }

    @objc func findPrevious(_ sender: Any?) {
        activeViewer?.findPrevious()
    }

    @objc func selectNextWindow(_ sender: Any?) {
        activeViewer?.selectNextWindow()
    }

    @objc func selectPreviousWindow(_ sender: Any?) {
        activeViewer?.selectPreviousWindow()
    }

    private var activeViewer: ViewerWindowController? {
        if let controller = NSApplication.shared.keyWindow?.windowController as? ViewerWindowController {
            return controller
        }
        return viewerWindowControllers.values.first
    }

    private func claimServerPort() -> Bool {
        if let server = ViewerMessageServer(openHandler: { [weak self] fileURL in
            self?.openDocumentIfValid(at: fileURL)
        }) {
            messageServer = server
            return true
        }

        // Two launchers may race before the first server has registered its
        // message port. The process that loses ownership forwards its file and exits.
        for _ in 0..<5 {
            if ViewerMessageClient.openInRunningViewer(initialFileURL) {
                return false
            }
            usleep(10_000)
        }
        return false
    }

    private func openDocumentIfValid(at fileURL: URL) {
        var isDirectory = ObjCBool(false)
        guard FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            NSSound.beep()
            return
        }
        openDocument(at: fileURL)
    }

    private func openDocument(at fileURL: URL) {
        idleTimer?.invalidate()
        idleTimer = nil

        let controller = ViewerWindowController(fileURL: fileURL)
        guard let window = controller.window else { return }
        window.delegate = self
        viewerWindowControllers[ObjectIdentifier(window)] = controller

        controller.onInitialDocumentReady = { [weak controller] in
            guard let controller else { return }
            controller.showWindow(nil)
            NSApplication.shared.unhide(nil)
            NSApplication.shared.activate(ignoringOtherApps: true)
        }
        controller.beginLoading()
    }

    private func scheduleIdleTermination() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(
            timeInterval: idleTimeout,
            target: self,
            selector: #selector(idleTimerDidFire(_:)),
            userInfo: nil,
            repeats: false
        )
    }

    @objc private func idleTimerDidFire(_ timer: Timer) {
        guard viewerWindowControllers.isEmpty else { return }
        NSApplication.shared.terminate(nil)
    }
}
