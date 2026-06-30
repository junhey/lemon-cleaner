import SwiftUI

struct SystemTabView: View {
    @ObservedObject var monitor: SystemMonitorService

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                storageRow
                networkRow
                NetworkGraphView(
                    uploadHistory: monitor.metrics.uploadHistory,
                    downloadHistory: monitor.metrics.downloadHistory
                )
                .frame(height: 64)
                .padding(.horizontal, AppTheme.panelHorizontalPadding)
            }
            .padding(.vertical, 6)
        }
    }

    private var storageRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "internaldrive")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text("Left \(ByteFormatter.format(Int64(monitor.metrics.diskFreeBytes))) / Total \(ByteFormatter.format(Int64(monitor.metrics.diskTotalBytes)))")
                .font(.system(size: 12))
            Spacer()
        }
        .padding(.horizontal, AppTheme.panelHorizontalPadding)
    }

    private var networkRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "globe")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up").foregroundStyle(AppTheme.accent)
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
        .padding(.horizontal, AppTheme.panelHorizontalPadding)
    }
}
