import SwiftUI

struct SystemTabView: View {
    @ObservedObject var monitor: SystemMonitorService
    @ObservedObject var privacyMonitor: PrivacyMonitorService
    @ObservedObject private var settings = UserSettings.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                metricsRow
                storageRow
                networkRow
                NetworkGraphView(
                    uploadHistory: monitor.metrics.uploadHistory,
                    downloadHistory: monitor.metrics.downloadHistory
                )
                .frame(height: 80)
                .padding(.horizontal, 16)

                if settings.showPrivacyBanner {
                    privacyBanner
                }

                PrivacyToggleGrid(privacyMonitor: privacyMonitor)
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
    }

    private var metricsRow: some View {
        HStack(spacing: 0) {
            metricCell(
                value: monitor.metrics.cpuTemperature.map { "\(Int($0))°C" } ?? "N/A",
                label: "CPU",
                warning: (monitor.metrics.cpuTemperature ?? 0) > 80
            )
            metricCell(
                value: monitor.metrics.fanSpeed.map { "\($0) R" } ?? "N/A",
                label: "Fan speed"
            )
            metricCell(
                value: ByteFormatter.formatPercent(monitor.metrics.diskUsagePercent),
                label: "Disk usage"
            )
        }
        .padding(.horizontal, 16)
    }

    private func metricCell(value: String, label: String, warning: Bool = false) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(warning ? AppTheme.warningOrange : .primary)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var storageRow: some View {
        HStack {
            Image(systemName: "internaldrive")
                .foregroundStyle(.secondary)
            Text("Left \(ByteFormatter.format(Int64(monitor.metrics.diskFreeBytes))) / Total \(ByteFormatter.format(Int64(monitor.metrics.diskTotalBytes)))")
                .font(.system(size: 12))
            Spacer()
            LinkButton(title: "More info") {
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()))
            }
        }
        .padding(.horizontal, 16)
    }

    private var networkRow: some View {
        HStack {
            Image(systemName: "globe")
                .foregroundStyle(.secondary)
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up").foregroundStyle(AppTheme.linkBlue)
                    Text(ByteFormatter.formatSpeed(monitor.metrics.uploadSpeed))
                }
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down").foregroundStyle(AppTheme.cleanGreen)
                    Text(ByteFormatter.formatSpeed(monitor.metrics.downloadSpeed))
                }
            }
            .font(.system(size: 12))
            Spacer()
            LinkButton(title: "Test speed") {
                if let url = URL(string: "https://fast.com") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var privacyBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "shield.fill")
                .foregroundStyle(AppTheme.lemonAccent)
            Text("New auto-operation prompts to monitor unauthorized PC usage.")
                .font(.system(size: 11))
                .foregroundStyle(.primary)
            Spacer()
            LinkButton(title: "Enable") {
                privacyMonitor.openPrivacySettings()
            }
            Button {
                settings.showPrivacyBanner = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppTheme.lemonAccent.opacity(0.12))
        )
        .padding(.horizontal, 16)
    }
}
