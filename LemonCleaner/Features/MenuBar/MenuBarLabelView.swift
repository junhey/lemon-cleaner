import SwiftUI

struct MenuBarLabelView: View {
    let metrics: SystemMetrics

    var body: some View {
        Text(compactLine)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .padding(.horizontal, 4)
    }

    private var compactLine: String {
        let cpu = ByteFormatter.formatPercent(metrics.cpuUsage)
        let mem = ByteFormatter.formatPercent(metrics.memoryUsage)
        let sen = metrics.cpuTemperature.map { "\(Int($0))°C" } ?? "N/A"
        let up = ByteFormatter.formatSpeed(metrics.uploadSpeed)
        let down = ByteFormatter.formatSpeed(metrics.downloadSpeed)
        return "\(cpu) CPU  \(mem) MEM  \(sen) SEN  ↑ \(up) ↓ \(down)"
    }
}
