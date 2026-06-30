import AppKit
import SwiftUI

/// Opens the main `WindowGroup(id: "main")` from MenuBarExtra, where `@Environment(\.openWindow)` is a no-op.
@MainActor
enum MainWindowPresenter {
    private static let openEvent = "open-main"
    private static var openAction: OpenWindowAction?

    static func register(_ action: OpenWindowAction) {
        openAction = action
    }

    static func present() {
        NSApp.activate(ignoringOtherApps: true)

        if let existing = NSApp.windows.first(where: isMainWindow) {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        openAction?(id: "main")

        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: isMainWindow) {
                window.makeKeyAndOrderFront(nil)
            } else {
                openViaExternalEvent()
            }
        }
    }

    static func focusExistingMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: isMainWindow)?.makeKeyAndOrderFront(nil)
    }

    private static func openViaExternalEvent() {
        guard let url = URL(string: "airy://\(openEvent)") else { return }
        NSWorkspace.shared.open(url)
    }

    private static func isMainWindow(_ window: NSWindow) -> Bool {
        window.title == "Airy" || window.identifier?.rawValue.contains("main") == true
    }
}

struct MainWindowOpenActionRegistrar: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear { MainWindowPresenter.register(openWindow) }
    }
}
