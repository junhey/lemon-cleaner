import SwiftUI
import AppKit

struct FooterBar: View {
    var onLaunch: () -> Void

    var body: some View {
        HStack {
            SettingsMenu()
            Spacer(minLength: 8)
            Button(action: onLaunch) {
                Text("Open Airy")
                    .font(.system(size: 13, weight: .medium))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: AppTheme.cardShadow, radius: 2, y: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.panelHorizontalPadding)
        .padding(.vertical, 6)
        .background(AppTheme.footerBackground)
    }
}

struct SettingsMenu: View {
    var body: some View {
        SettingsMenuButton()
            .fixedSize()
    }
}

private struct SettingsMenuButton: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let container = NSView(frame: .zero)
        let button = NSButton(frame: .zero)
        button.title = ""
        button.bezelStyle = .inline
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.target = context.coordinator
        button.action = #selector(Coordinator.showMenu(_:))
        button.image = menuBarImage()
        button.toolTip = "Settings"
        button.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        container.setContentHuggingPriority(.required, for: .horizontal)
        container.setContentCompressionResistancePriority(.required, for: .horizontal)
        context.coordinator.button = button
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private func menuBarImage() -> NSImage {
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        let gear = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Settings")?
            .withSymbolConfiguration(config) ?? NSImage()
        let chevron = NSImage(systemSymbolName: "chevron.down", accessibilityDescription: nil)?
            .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 8, weight: .semibold)) ?? NSImage()
        let size = NSSize(width: gear.size.width + chevron.size.width + 2, height: max(gear.size.height, chevron.size.height))
        let composite = NSImage(size: size)
        composite.lockFocus()
        gear.draw(at: NSPoint(x: 0, y: (size.height - gear.size.height) / 2), from: .zero, operation: .sourceOver, fraction: 0.55)
        chevron.draw(at: NSPoint(x: gear.size.width + 2, y: (size.height - chevron.size.height) / 2), from: .zero, operation: .sourceOver, fraction: 0.45)
        composite.unlockFocus()
        return composite
    }

    final class Coordinator: NSObject {
        weak var button: NSButton?

        @objc func showMenu(_ sender: NSButton) {
            let menu = NSMenu()
            let prefs = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
            prefs.target = self
            menu.addItem(prefs)
            menu.addItem(.separator())
            let about = NSMenuItem(title: "About Airy", action: #selector(showAbout), keyEquivalent: "")
            about.target = self
            menu.addItem(about)
            let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
            quit.target = self
            menu.addItem(quit)
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height + 4), in: sender)
        }

        @objc private func openPreferences() {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }

        @objc private func showAbout() {
            NSApp.orderFrontStandardAboutPanel(nil)
        }

        @objc private func quitApp() {
            NSApp.terminate(nil)
        }
    }
}
