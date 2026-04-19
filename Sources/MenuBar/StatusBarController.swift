import Cocoa
import Combine
import SwiftUI

@MainActor
final class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var aboutWindow: NSWindow?

    let configManager = ConfigManager()
    private var cancellables = Set<AnyCancellable>()

    // Tag constants for identifying menu sections
    private static let presetBaseTag = 200
    private static let placeholderTag = 300

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = MenuBarIcon.make()
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        // Rebuild menu whenever presets change
        configManager.$presets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.rebuildMenu()
            }
            .store(in: &cancellables)

        rebuildMenu()
    }

    // MARK: - Menu

    private func rebuildMenu() {
        guard let menu = statusItem.menu else { return }
        menu.removeAllItems()

        // Preset items
        if configManager.presets.isEmpty {
            let placeholder = NSMenuItem(
                title: "No presets — add one in Settings",
                action: nil,
                keyEquivalent: ""
            )
            placeholder.isEnabled = false
            placeholder.tag = Self.placeholderTag
            menu.addItem(placeholder)
        } else {
            let activeID = PreferencesStore.shared.activePresetID
            for (index, preset) in configManager.presets.enumerated() {
                let item = NSMenuItem(
                    title: preset.name,
                    action: #selector(applyPreset(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.tag = Self.presetBaseTag + index
                item.representedObject = preset.id
                if preset.id.uuidString == activeID {
                    item.state = .on
                }
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        // Revert to launch state
        let revertItem = NSMenuItem(
            title: "Revert to Original",
            action: #selector(revertToBaseline(_:)),
            keyEquivalent: ""
        )
        revertItem.target = self
        menu.addItem(revertItem)

        menu.addItem(.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // How to Use
        let howToItem = NSMenuItem(
            title: "How to Use...",
            action: #selector(openOnboarding(_:)),
            keyEquivalent: ""
        )
        howToItem.target = self
        menu.addItem(howToItem)

        // About
        let aboutItem = NSMenuItem(
            title: "About ScreenDial",
            action: #selector(openAbout(_:)),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit ScreenDial",
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }

    // MARK: - Actions

    @objc private func applyPreset(_ sender: NSMenuItem) {
        guard let presetID = sender.representedObject as? UUID
        else { return }

        // Toggle off if clicking the currently active preset
        if presetID.uuidString == PreferencesStore.shared.activePresetID {
            PresetApplicator.deactivate()
            PreferencesStore.shared.activePresetID = ""
        } else if let preset = configManager.presets.first(where: { $0.id == presetID }) {
            PresetApplicator.apply(preset)
            PreferencesStore.shared.activePresetID = presetID.uuidString
        }

        rebuildMenu()
    }

    @objc private func revertToBaseline(_ sender: Any?) {
        LaunchBaseline.shared.restore()
        rebuildMenu()
    }

    @objc private func openSettings(_ sender: Any?) {
        if let existing = settingsWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = ShortcutWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "ScreenDial Settings"
        window.contentView = NSHostingView(
            rootView: SettingsView(configManager: configManager)
        )
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    @objc private func openOnboarding(_ sender: Any?) {
        showOnboarding()
    }

    func showOnboarding() {
        if let existing = onboardingWindow, existing.isVisible {
            existing.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = ShortcutWindow(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "How to Use ScreenDial"
        window.contentView = NSHostingView(rootView: OnboardingView())
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        NSApp.setActivationPolicy(.regular)
        window.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }

    @objc private func openAbout(_ sender: Any?) {
        if let existing = aboutWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = ShortcutWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "About ScreenDial"
        window.contentView = NSHostingView(rootView: AboutView())
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow = window
    }

    @objc private func quit(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}

// MARK: - NSMenuDelegate

extension StatusBarController: NSMenuDelegate {
    /// Fully rebuild the menu each time it opens so preset checkmarks and
    /// the history submenu always reflect current state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }
}

// MARK: - NSWindowDelegate

extension StatusBarController: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        DispatchQueue.main.async {
            let hasVisibleWindow = NSApp.windows.contains { $0.isVisible && $0.level == .normal }
            if !hasVisibleWindow {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}
