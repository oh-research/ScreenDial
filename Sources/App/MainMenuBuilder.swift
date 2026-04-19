import Cocoa

/// Builds the application's main menu.
///
/// `.accessory` apps launched via raw `NSApplication` (not SwiftUI's `@main App`)
/// have no main menu by default. Without it, system key equivalents such as
/// `Ctrl+Cmd+Space` (Emoji & Symbols) and the standard Cut/Copy/Paste/Undo
/// shortcuts fail to reach any responder. Installing a minimal Edit menu
/// restores those behaviors in every `NSTextField` / `NSTextView` the app shows.
@MainActor
enum MainMenuBuilder {
    static func install() {
        let mainMenu = NSMenu()
        mainMenu.addItem(makeEditMenuItem())
        NSApp.mainMenu = mainMenu
    }

    private static func makeEditMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "Edit")

        menu.addItem(
            withTitle: "Undo",
            action: Selector(("undo:")),
            keyEquivalent: "z"
        )
        menu.addItem(
            withTitle: "Redo",
            action: Selector(("redo:")),
            keyEquivalent: "Z"
        )
        menu.addItem(.separator())

        menu.addItem(
            withTitle: "Cut",
            action: #selector(NSText.cut(_:)),
            keyEquivalent: "x"
        )
        menu.addItem(
            withTitle: "Copy",
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        menu.addItem(
            withTitle: "Paste",
            action: #selector(NSText.paste(_:)),
            keyEquivalent: "v"
        )
        menu.addItem(
            withTitle: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        menu.addItem(.separator())

        let emoji = NSMenuItem(
            title: "Emoji & Symbols",
            action: #selector(NSApplication.orderFrontCharacterPalette(_:)),
            keyEquivalent: " "
        )
        emoji.keyEquivalentModifierMask = [.control, .command]
        menu.addItem(emoji)

        item.submenu = menu
        return item
    }
}
