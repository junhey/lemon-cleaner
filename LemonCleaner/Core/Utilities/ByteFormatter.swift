import Foundation

enum ByteFormatter {
    static func format(_ bytes: Int64) -> String {
        format(UInt64(max(0, bytes)))
    }

    static func format(_ bytes: UInt64) -> String {
        let value = Double(bytes)
        let units = ["B", "KB", "MB", "GB", "TB"]
        var idx = 0
        var scaled = value
        while scaled >= 1024, idx < units.count - 1 {
            scaled /= 1024
            idx += 1
        }
        if idx == 0 {
            return "\(bytes) B"
        }
        let formatted = scaled >= 100 ? String(format: "%.0f", scaled)
            : scaled >= 10 ? String(format: "%.1f", scaled)
            : String(format: "%.2f", scaled)
        return "\(formatted) \(units[idx])"
    }

    static func formatSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.0f B/s", bytesPerSecond)
        }
        if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        }
        return String(format: "%.1f MB/s", bytesPerSecond / 1024 / 1024)
    }

    static func formatPercent(_ value: Double) -> String {
        "\(Int(value.rounded()))%"
    }

    /// Compact speed for menu bar: `10K`, `1.2M`, `512`
    static func formatCompactSpeed(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return "\(Int(bytesPerSecond.rounded()))"
        }
        if bytesPerSecond < 1024 * 1024 {
            let kb = bytesPerSecond / 1024
            return kb >= 100 ? String(format: "%.0fK", kb) : String(format: "%.0fK", kb.rounded())
        }
        let mb = bytesPerSecond / 1024 / 1024
        return mb >= 10 ? String(format: "%.0fM", mb) : String(format: "%.1fM", mb)
    }
}
