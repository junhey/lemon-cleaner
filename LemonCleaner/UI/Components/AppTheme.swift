import SwiftUI

enum AppTheme {
    static let lemonAccent = Color(red: 1.0, green: 0.604, blue: 0.18)
    static let cleanGreen = Color(red: 0.204, green: 0.78, blue: 0.349)
    static let linkBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let warningOrange = Color(red: 1.0, green: 0.584, blue: 0.0)
    static let panelBackground = Color(nsColor: .windowBackgroundColor)
    static let sidebarBackground = Color(nsColor: .controlBackgroundColor)
    static let footerBackground = Color(nsColor: .controlBackgroundColor)
    static let subtleText = Color.secondary
    static let cardShadow = Color.black.opacity(0.06)

    static let panelWidth: CGFloat = 360
    static let panelHeight: CGFloat = 520
    static let panelCornerRadius: CGFloat = 12
}

struct RoundedCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
    }
}

struct PrimaryButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
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
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppTheme.linkBlue)
        }
        .buttonStyle(.plain)
    }
}
