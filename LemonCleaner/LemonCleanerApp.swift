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

        WindowGroup("Lemon Cleaner", id: "main") {
            MainDashboardView()
        }
        .defaultSize(width: 900, height: 600)

        Settings {
            SettingsView()
        }
    }
}
