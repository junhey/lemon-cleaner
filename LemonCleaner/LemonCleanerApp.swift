import SwiftUI

@main
struct LemonCleanerApp: App {
    @StateObject private var monitor = SystemMonitorService()
    @StateObject private var settings = UserSettings.shared

    var body: some Scene {
        MenuBarExtra {
            PopupPanelView()
                .environmentObject(monitor)
        } label: {
            MenuBarLabelView(metrics: monitor.metrics)
        }
        .menuBarExtraStyle(.window)

        WindowGroup("Airy", id: "main") {
            MainDashboardView()
        }
        .defaultSize(width: 800, height: 520)

        Settings {
            SettingsView()
        }
    }
}
