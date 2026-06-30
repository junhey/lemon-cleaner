import Foundation

enum PrivacyFeature: String, CaseIterable, Identifiable {
    case camera
    case microphone
    case screen
    case automation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .camera: return "Camera Privacy"
        case .microphone: return "System Audio"
        case .screen: return "Screen Privacy"
        case .automation: return "Automation Alert"
        }
    }

    var iconName: String {
        switch self {
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        case .screen: return "display"
        case .automation: return "gearshape.2.fill"
        }
    }
}

struct PrivacyFeatureStatus: Identifiable {
    let feature: PrivacyFeature
    var isEnabled: Bool
    var statusText: String {
        isEnabled ? "Enabled" : "Not enabled"
    }

    var id: String { feature.id }
}
