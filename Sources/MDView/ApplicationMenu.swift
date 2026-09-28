import AppKit

@MainActor
enum ApplicationMenu {
    static func install(target: AppDelegate) {
        let mainMenu = NSMenu()
        NSApplication.shared.mainMenu = mainMenu

        let applicationItem = NSMenuItem()
        mainMenu.addItem(applicationItem)
        let applicationMenu = NSMenu()
        applicationItem.submenu = applicationMenu
        applicationMenu.addItem(
            withTitle: "About mdview",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        applicationMenu.addItem(.separator())
        let quitItem = applicationMenu.addItem(
            withTitle: "Quit mdview",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = [.command]

        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        fileItem.submenu = fileMenu
        let closeItem = fileMenu.addItem(
            withTitle: "Close Window",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        closeItem.keyEquivalentModifierMask = [.command]

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        let copyItem = editMenu.addItem(
            withTitle: "Copy",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        copyItem.keyEquivalentModifierMask = [.command]
        editMenu.addItem(.separator())
        addItem(
            to: editMenu,
            title: "Find…",
            action: #selector(AppDelegate.showFind(_:)),
            key: "f",
            target: target
        )
        addItem(
            to: editMenu,
            title: "Find Next",
            action: #selector(AppDelegate.findNext(_:)),
            key: "g",
            target: target
        )
        addItem(
            to: editMenu,
            title: "Find Previous",
            action: #selector(AppDelegate.findPrevious(_:)),
            key: "g",
            modifiers: [.command, .shift],
            target: target
        )

        let viewItem = NSMenuItem()
        mainMenu.addItem(viewItem)
        let viewMenu = NSMenu(title: "View")
        viewItem.submenu = viewMenu

        addItem(
            to: viewMenu,
            title: "Reload",
            action: #selector(AppDelegate.reloadDocument(_:)),
            key: "r",
            target: target
        )
        viewMenu.addItem(.separator())
        addItem(
            to: viewMenu,
            title: "Actual Size",
            action: #selector(AppDelegate.resetZoom(_:)),
            key: "0",
            target: target
        )
        addItem(
            to: viewMenu,
            title: "Zoom In",
            action: #selector(AppDelegate.zoomIn(_:)),
            key: "=",
            target: target
        )
        addItem(
            to: viewMenu,
            title: "Zoom Out",
            action: #selector(AppDelegate.zoomOut(_:)),
            key: "-",
            target: target
        )
    }

    private static func addItem(
        to menu: NSMenu,
        title: String,
        action: Selector,
        key: String,
        modifiers: NSEvent.ModifierFlags = [.command],
        target: AnyObject
    ) {
        let item = menu.addItem(withTitle: title, action: action, keyEquivalent: key)
        item.target = target
        item.keyEquivalentModifierMask = modifiers
    }
}
