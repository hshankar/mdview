import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let fileURL: URL
    private var viewerWindowController: ViewerWindowController?

    init(fileURL: URL) {
        self.fileURL = fileURL
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = ViewerWindowController(fileURL: fileURL)
        viewerWindowController = controller
        controller.showWindow(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
