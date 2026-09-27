import AppKit

@MainActor
enum ApplicationIcon {
    static func install(on application: NSApplication) {
        guard let image = image() else { return }
        application.applicationIconImage = image
    }

    static func image(bundle: Bundle = .module) -> NSImage? {
        guard let url = bundle.url(forResource: "AppIcon", withExtension: "icns") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}
