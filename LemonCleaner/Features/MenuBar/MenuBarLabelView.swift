import SwiftUI

struct MenuBarLabelView: View {
    let metrics: SystemMetrics

    private var cpuPercent: Int { Int(metrics.cpuUsage.rounded()) }
    private var memPercent: Int { Int(metrics.memoryUsage.rounded()) }
    private var senText: String {
        metrics.cpuTemperature.map { "\(Int($0))°C" } ?? "–"
    }
    private var senIsHigh: Bool {
        (metrics.cpuTemperature ?? 0) > 80
    }

    var body: some View {
        HStack(spacing: 6) {
            metricColumn(value: "\(cpuPercent)%", label: "CPU")
            columnDivider
            metricColumn(value: "\(memPercent)%", label: "MEM")
            columnDivider
            metricColumn(value: senText, label: "SEN", valueColor: senIsHigh ? AppTheme.warningOrange : nil)
            columnDivider
            networkColumn
        }
        .fixedSize()
        .padding(.horizontal, 2)
    }

    private var columnDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.22))
            .frame(width: 0.5, height: 20)
    }

    private func metricColumn(value: String, label: String, valueColor: Color? = nil) -> some View {
        VStack(spacing: 1) {
            Text(value)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(valueColor ?? .primary)
            Text(label)
                .font(.system(size: 7, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var networkColumn: some View {
        VStack(spacing: 1) {
            Text("↑ \(ByteFormatter.formatCompactSpeed(metrics.uploadSpeed))")
            Text("↓ \(ByteFormatter.formatCompactSpeed(metrics.downloadSpeed))")
        }
        .font(.system(size: 8, weight: .medium, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(.primary)
    }
}
