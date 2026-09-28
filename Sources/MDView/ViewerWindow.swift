import AppKit

final class ViewerWindow: NSWindow {
    var commandKeyHandler: ((NSEvent) -> Bool)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if commandKeyHandler?(event) == true {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}
