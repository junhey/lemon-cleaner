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

    private enum Keys {
        static let largeFileThreshold = "largeFileThresholdMB"
        static let scanFullDisk = "scanFullDisk"
    }

    private init() {
        let defaults = UserDefaults.standard
        largeFileThresholdMB = defaults.object(forKey: Keys.largeFileThreshold) as? Int ?? 50
        scanFullDisk = defaults.bool(forKey: Keys.scanFullDisk)
    }
}
