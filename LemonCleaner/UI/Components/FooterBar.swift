import SwiftUI
import AppKit

struct FooterBar: View {
    var onLaunch: () -> Void
    var onFeedback: () -> Void

    var body: some View {
        HStack {
            SettingsMenu()
            Spacer()
            Button(action: onLaunch) {
                Text("Launch Lemon")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: AppTheme.cardShadow, radius: 2, y: 1)
                    )
            }
            .buttonStyle(.plain)
            Spacer()
            Button(action: onFeedback) {
                Image(systemName: "ellipsis.bubble")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.footerBackground)
    }
}

struct SettingsMenu: View {
    var body: some View {
        Menu {
            Button("Update") {
                if let url = URL(string: "https://github.com/junhey/lemon-cleaner/releases") {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("About Lemon Cleaner") {
                NSApp.orderFrontStandardAboutPanel(nil)
            }
            Button("Preferences…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            Divider()
            Button("Quit") {
                NSApp.terminate(nil)
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
    }
}
