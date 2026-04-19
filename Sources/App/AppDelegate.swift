import Cocoa
import os

private let appLogger = Logger(subsystem: "com.ohresearch.screendial", category: "ScreenDial")

func debugLog(_ msg: String) {
    appLogger.debug("\(msg, privacy: .public)")
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusBarController = StatusBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        LaunchBaseline.shared.record()
        debugLog("[ScreenDial] launched")
        MainMenuBuilder.install()
        statusBarController.setup()

        if !PreferencesStore.shared.onboardingCompleted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
                statusBarController.showOnboarding()
            }
        }
    }
}
