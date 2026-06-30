import Foundation

struct SystemMetrics: Equatable {
    var cpuUsage: Double = 0
    var memoryUsage: Double = 0
    var memoryUsedBytes: UInt64 = 0
    var memoryTotalBytes: UInt64 = 0
    var cpuTemperature: Double?
    var fanSpeed: Int?
    var diskUsagePercent: Double = 0
    var diskFreeBytes: UInt64 = 0
    var diskTotalBytes: UInt64 = 0
    var uploadSpeed: Double = 0
    var downloadSpeed: Double = 0
    var uploadHistory: [Double] = Array(repeating: 0, count: 60)
    var downloadHistory: [Double] = Array(repeating: 0, count: 60)
}

struct NetworkSample: Equatable {
    let upload: Double
    let download: Double
}
