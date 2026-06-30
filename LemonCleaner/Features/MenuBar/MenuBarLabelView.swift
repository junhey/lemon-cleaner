import SwiftUI

struct MenuBarLabelView: View {
    let metrics: SystemMetrics

    var body: some View {
        Text(compactLine)
            .font(.system(size: 9, weight: .medium, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 2)
    }

    private var compactLine: String {
        let cpu = Int(metrics.cpuUsage.rounded())
        let mem = Int(metrics.memoryUsage.rounded())
        let sen = metrics.cpuTemperature.map { "\(Int($0))" } ?? "–"
        let up = ByteFormatter.formatCompactSpeed(metrics.uploadSpeed)
        let down = ByteFormatter.formatCompactSpeed(metrics.downloadSpeed)
        return "\(cpu)|\(mem)|\(sen)|↑\(up) ↓\(down)"
    }
}
