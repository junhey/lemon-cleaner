import SwiftUI

struct MenuBarLabelView: View {
    let metrics: SystemMetrics

    var body: some View {
        HStack(spacing: 6) {
            statLabel("CPU", value: ByteFormatter.formatPercent(metrics.cpuUsage))
            statLabel("MEM", value: ByteFormatter.formatPercent(metrics.memoryUsage))
            if let temp = metrics.cpuTemperature {
                statLabel("SEN", value: "\(Int(temp))°C", warning: temp > 80)
            }
            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 8))
                Text(ByteFormatter.formatSpeed(metrics.uploadSpeed))
            }
            HStack(spacing: 2) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 8))
                Text(ByteFormatter.formatSpeed(metrics.downloadSpeed))
            }
        }
        .font(.system(size: 11, weight: .medium, design: .rounded))
        .monospacedDigit()
    }

    private func statLabel(_ title: String, value: String, warning: Bool = false) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(warning ? AppTheme.warningOrange : .primary)
        }
    }
}

struct MenuBarStatsBar: View {
    let metrics: SystemMetrics

    var body: some View {
        HStack(spacing: 0) {
            statCell("CPU", ByteFormatter.formatPercent(metrics.cpuUsage), warning: metrics.cpuUsage > 70)
            divider
            statCell("MEM", ByteFormatter.formatPercent(metrics.memoryUsage), warning: metrics.memoryUsage > 70)
            divider
            if let temp = metrics.cpuTemperature {
                statCell("SEN", "\(Int(temp))°C", warning: temp > 80)
            } else {
                statCell("SEN", "N/A")
            }
            divider
            VStack(spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up").foregroundStyle(AppTheme.linkBlue)
                    Text(ByteFormatter.formatSpeed(metrics.uploadSpeed))
                }
                HStack(spacing: 3) {
                    Image(systemName: "arrow.down").foregroundStyle(AppTheme.cleanGreen)
                    Text(ByteFormatter.formatSpeed(metrics.downloadSpeed))
                }
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .monospacedDigit()
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor).opacity(0.3))
            .frame(width: 1, height: 28)
    }

    private func statCell(_ title: String, _ value: String, warning: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(warning ? AppTheme.warningOrange : .primary)
                .monospacedDigit()
            Text(title)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
