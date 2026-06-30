import Foundation
import Combine

@MainActor
final class UserSettings: ObservableObject {
    static let shared = UserSettings()

    @Published var largeFileThresholdMB: Int {
        didSet { UserDefaults.standard.set(largeFileThresholdMB, forKey: Keys.largeFileThreshold) }
    }

    @Published var scanFullDisk: Bool {
        didSet { UserDefaults.standard.set(scanFullDisk, forKey: Keys.scanFullDisk) }
    }

    @Published var showPrivacyBanner: Bool {
        didSet { UserDefaults.standard.set(showPrivacyBanner, forKey: Keys.showPrivacyBanner) }
    }

    @Published var privacyToggles: [PrivacyFeature: Bool] {
        didSet {
            for (key, value) in privacyToggles {
                UserDefaults.standard.set(value, forKey: Keys.privacyToggle(key))
            }
        }
    }

    private enum Keys {
        static let largeFileThreshold = "largeFileThresholdMB"
        static let scanFullDisk = "scanFullDisk"
        static let showPrivacyBanner = "showPrivacyBanner"
        static func privacyToggle(_ feature: PrivacyFeature) -> String {
            "privacy.\(feature.rawValue)"
        }
    }

    private init() {
        let defaults = UserDefaults.standard
        largeFileThresholdMB = defaults.object(forKey: Keys.largeFileThreshold) as? Int ?? 50
        scanFullDisk = defaults.bool(forKey: Keys.scanFullDisk)
        showPrivacyBanner = defaults.object(forKey: Keys.showPrivacyBanner) as? Bool ?? true
        var toggles: [PrivacyFeature: Bool] = [:]
        for feature in PrivacyFeature.allCases {
            toggles[feature] = defaults.bool(forKey: Keys.privacyToggle(feature))
        }
        privacyToggles = toggles
    }
}
