import SwiftUI

@MainActor
final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    @AppStorage("onboardingCompleted") var onboardingCompleted: Bool = false
    @AppStorage("activePresetID") var activePresetID: String = ""
}
