import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.35, green: 0.62, blue: 0.98)
    static let cleanGreen = Color(red: 0.22, green: 0.72, blue: 0.45)
    static let linkBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let warningOrange = Color(red: 1.0, green: 0.55, blue: 0.2)
    static let panelBackground = Color(nsColor: .windowBackgroundColor)
    static let sidebarBackground = Color(nsColor: .controlBackgroundColor)
    static let footerBackground = Color(nsColor: .controlBackgroundColor).opacity(0.6)
    static let subtleText = Color.secondary
    static let cardShadow = Color.black.opacity(0.04)

    static let panelWidth: CGFloat = 320
    static let panelHeight: CGFloat = 360
    static let panelCornerRadius: CGFloat = 10
}

struct PrimaryButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
                .background(Capsule().fill(color))
        }
        .buttonStyle(.plain)
    }
}

struct LinkButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.linkBlue)
        }
        .buttonStyle(.plain)
    }
}
