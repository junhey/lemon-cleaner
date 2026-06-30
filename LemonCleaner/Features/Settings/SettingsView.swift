import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = UserSettings.shared

    var body: some View {
        Form {
            Section("Scanning") {
                Stepper("Large file threshold: \(settings.largeFileThresholdMB) MB", value: $settings.largeFileThresholdMB, in: 10...500, step: 10)
                Toggle("Scan full disk (requires Full Disk Access)", isOn: $settings.scanFullDisk)
            }
            Section("Permissions") {
                Text("Grant Full Disk Access in System Settings → Privacy & Security to scan all files.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Open Full Disk Access Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            Section("About") {
                LabeledContent("Version", value: "0.0.2")
                LabeledContent("App", value: "Airy")
                LabeledContent("Bundle ID", value: "com.junhey.LemonCleaner")
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 300)
    }
}
