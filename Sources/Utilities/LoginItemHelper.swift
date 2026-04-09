import ServiceManagement

/// Wraps SMAppService to register/unregister the app as a login item.
@MainActor
enum LoginItemHelper {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func enable() -> Bool {
        do {
            try SMAppService.mainApp.register()
            return true
        } catch {
            return false
        }
    }

    @discardableResult
    static func disable() -> Bool {
        do {
            try SMAppService.mainApp.unregister()
            return true
        } catch {
            return false
        }
    }

    static func setEnabled(_ enabled: Bool) {
        if enabled {
            enable()
        } else {
            disable()
        }
    }
}
