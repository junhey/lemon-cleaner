import SwiftUI
import AppKit

struct FooterBar: View {
    var onLaunch: () -> Void

    var body: some View {
        HStack {
            SettingsMenu()
            Spacer()
            Button(action: onLaunch) {
                Text("Open Airy")
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.footerBackground)
    }
}

struct SettingsMenu: View {
    var body: some View {
        Menu {
            Button("Preferences…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            Divider()
            Button("About Airy") {
                NSApp.orderFrontStandardAboutPanel(nil)
            }
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
