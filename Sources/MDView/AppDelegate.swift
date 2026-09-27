import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let fileURL: URL
    private var viewerWindowController: ViewerWindowController?

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        ApplicationMenu.install(target: self)

        let controller = ViewerWindowController(fileURL: fileURL)
        viewerWindowController = controller
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @objc func reloadDocument(_ sender: Any?) {
        viewerWindowController?.reload()
    }

    @objc func zoomIn(_ sender: Any?) {
        viewerWindowController?.zoomIn()
    }

    @objc func zoomOut(_ sender: Any?) {
        viewerWindowController?.zoomOut()
    }

    @objc func resetZoom(_ sender: Any?) {
        viewerWindowController?.resetZoom()
    }
}
