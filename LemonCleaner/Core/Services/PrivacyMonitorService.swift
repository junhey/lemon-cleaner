import AVFoundation
import AppKit
import Foundation

@MainActor
final class PrivacyMonitorService: ObservableObject {
    @Published private(set) var statuses: [PrivacyFeatureStatus] = []

    func refresh() {
        statuses = PrivacyFeature.allCases.map { feature in
            PrivacyFeatureStatus(feature: feature, isEnabled: checkEnabled(feature))
        }
    }

    func setEnabled(_ feature: PrivacyFeature, enabled: Bool) {
        UserSettings.shared.privacyToggles[feature] = enabled
        refresh()
        if enabled {
            openPrivacySettings(for: feature)
        }
    }

    func openPrivacySettings(for feature: PrivacyFeature? = nil) {
        let urlString: String
        switch feature {
        case .camera:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        case .microphone:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .screen:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        case .automation, .none:
            urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation"
        }
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkEnabled(_ feature: PrivacyFeature) -> Bool {
        if let stored = UserSettings.shared.privacyToggles[feature], stored {
            return true
        }
        switch feature {
        case .camera:
            return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        case .microphone:
            return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        case .screen:
            return CGPreflightScreenCaptureAccess()
        case .automation:
            return NSWorkspace.shared.runningApplications.contains {
                ($0.bundleIdentifier ?? "").contains("automator") ||
                ($0.bundleIdentifier ?? "").contains("shortcut")
            }
        }
    }
}
