import SwiftUI

struct SystemTabView: View {
    @ObservedObject var monitor: SystemMonitorService

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                temperatureRow
                storageRow
                networkRow
                NetworkGraphView(
                    uploadHistory: monitor.metrics.uploadHistory,
                    downloadHistory: monitor.metrics.downloadHistory
                )
                .frame(height: 80)
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 8)
        }
    }

    private var temperatureRow: some View {
        HStack {
            Image(systemName: "thermometer.medium")
                .foregroundStyle(.secondary)
            Text("CPU temperature")
                .font(.system(size: 12))
            Spacer()
            Text(monitor.metrics.cpuTemperature.map { "\(Int($0))°C" } ?? "N/A")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle((monitor.metrics.cpuTemperature ?? 0) > 80 ? AppTheme.warningOrange : .primary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
    }

    private var storageRow: some View {
        HStack {
            Image(systemName: "internaldrive")
                .foregroundStyle(.secondary)
            Text("Left \(ByteFormatter.format(Int64(monitor.metrics.diskFreeBytes))) / Total \(ByteFormatter.format(Int64(monitor.metrics.diskTotalBytes)))")
                .font(.system(size: 12))
            Spacer()
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
        }
        .padding(.horizontal, 16)
    }
}
