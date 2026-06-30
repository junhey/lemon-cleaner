import Foundation
import Combine
import Darwin

@MainActor
final class SystemMonitorService: ObservableObject {
    @Published private(set) var metrics = SystemMetrics()

    private var timer: AnyCancellable?
    private var previousCPUInfo: host_cpu_load_info?
    private var previousNetworkBytes: (upload: UInt64, download: UInt64)?
    private var previousNetworkTime: Date?

    func start() {
        guard timer == nil else { return }
        refresh()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    func stop() {
        timer?.cancel()
        timer = nil
    }

    private func refresh() {
        var updated = metrics
        updated.cpuUsage = CPUStatsReader.usage(previous: &previousCPUInfo)
        let mem = MemoryStatsReader.snapshot()
        updated.memoryUsage = mem.percent
        updated.memoryUsedBytes = mem.used
        updated.memoryTotalBytes = mem.total
        let disk = DiskStatsReader.snapshot()
        updated.diskUsagePercent = disk.percent
        updated.diskFreeBytes = disk.free
        updated.diskTotalBytes = disk.total
        updated.cpuTemperature = SMCReader.readTemperature()
        updated.fanSpeed = SMCReader.readFanSpeed()
        let net = NetworkStatsReader.sample(previous: &previousNetworkBytes, previousTime: &previousNetworkTime)
        updated.uploadSpeed = net.upload
        updated.downloadSpeed = net.download
        updated.uploadHistory = appendHistory(metrics.uploadHistory, net.upload)
        updated.downloadHistory = appendHistory(metrics.downloadHistory, net.download)
        metrics = updated
    }

    private func appendHistory(_ history: [Double], _ value: Double) -> [Double] {
        var next = history
        if next.count >= 60 { next.removeFirst() }
        next.append(value)
        return next
    }
}

enum CPUStatsReader {
    static func usage(previous: inout host_cpu_load_info?) -> Double {
        var numCPUsU: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var numCPUs: mach_msg_type_number_t = 0

        let err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUsU, &cpuInfo, &numCPUs)
        guard err == KERN_SUCCESS, let cpuInfoPtr = cpuInfo else { return 0 }

        defer {
            let size = vm_size_t(UInt(numCPUs) * UInt(MemoryLayout<integer_t>.size))
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfoPtr), size)
        }

        let cpuLoad = cpuInfoPtr.withMemoryRebound(to: host_cpu_load_info.self, capacity: Int(numCPUsU)) { $0 }

        var totalUser: natural_t = 0
        var totalSystem: natural_t = 0
        var totalIdle: natural_t = 0
        var totalNice: natural_t = 0
        for i in 0..<Int(numCPUsU) {
            totalUser &+= cpuLoad[i].cpu_ticks.0
            totalSystem &+= cpuLoad[i].cpu_ticks.1
            totalIdle &+= cpuLoad[i].cpu_ticks.2
            totalNice &+= cpuLoad[i].cpu_ticks.3
        }

        let current = host_cpu_load_info(cpu_ticks: (totalUser, totalSystem, totalIdle, totalNice))
        defer { previous = current }

        guard let prev = previous else { return 0 }

        let deltaUser = Double(current.cpu_ticks.0 - prev.cpu_ticks.0)
        let deltaSystem = Double(current.cpu_ticks.1 - prev.cpu_ticks.1)
        let deltaIdle = Double(current.cpu_ticks.2 - prev.cpu_ticks.2)
        let deltaNice = Double(current.cpu_ticks.3 - prev.cpu_ticks.3)
        let totalDelta = deltaUser + deltaSystem + deltaIdle + deltaNice
        guard totalDelta > 0 else { return 0 }
        return min(100, max(0, (deltaUser + deltaSystem + deltaNice) / totalDelta * 100))
    }
}

enum MemoryStatsReader {
    static func snapshot() -> (percent: Double, used: UInt64, total: UInt64) {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { ptr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, ptr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, 0, 0) }

        let pageSize = UInt64(vm_kernel_page_size)
        let active = UInt64(stats.active_count) * pageSize
        let wired = UInt64(stats.wire_count) * pageSize
        let compressed = UInt64(stats.compressor_page_count) * pageSize
        let used = active + wired + compressed

        let total = ProcessInfo.processInfo.physicalMemory
        let percent = total > 0 ? Double(used) / Double(total) * 100 : 0
        return (percent, used, total)
    }
}

enum DiskStatsReader {
    static func snapshot() -> (percent: Double, free: UInt64, total: UInt64) {
        let path = NSHomeDirectory()
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path),
              let total = attrs[.systemSize] as? NSNumber,
              let free = attrs[.systemFreeSize] as? NSNumber else {
            return (0, 0, 0)
        }
        let totalBytes = total.uint64Value
        let freeBytes = free.uint64Value
        let used = totalBytes > freeBytes ? totalBytes - freeBytes : 0
        let percent = totalBytes > 0 ? Double(used) / Double(totalBytes) * 100 : 0
        return (percent, freeBytes, totalBytes)
    }
}

enum NetworkStatsReader {
    static func sample(
        previous: inout (upload: UInt64, download: UInt64)?,
        previousTime: inout Date?
    ) -> (upload: Double, download: Double) {
        let current = currentBytes()
        let now = Date()
        defer {
            previous = current
            previousTime = now
        }
        guard let prev = previous, let prevTime = previousTime else {
            return (0, 0)
        }
        let interval = now.timeIntervalSince(prevTime)
        guard interval > 0 else { return (0, 0) }
        let upDelta = current.upload >= prev.upload ? current.upload - prev.upload : 0
        let downDelta = current.download >= prev.download ? current.download - prev.download : 0
        return (Double(upDelta) / interval, Double(downDelta) / interval)
    }

    private static func currentBytes() -> (upload: UInt64, download: UInt64) {
        var upload: UInt64 = 0
        var download: UInt64 = 0
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }

        var ptr = first
        while true {
            let flags = Int32(ptr.pointee.ifa_flags)
            let isUp = (flags & IFF_UP) != 0
            let isLoopback = (flags & IFF_LOOPBACK) != 0
            if isUp, !isLoopback, let data = ptr.pointee.ifa_data {
                let ifData = data.assumingMemoryBound(to: if_data.self).pointee
                download &+= UInt64(ifData.ifi_ibytes)
                upload &+= UInt64(ifData.ifi_obytes)
            }
            guard let next = ptr.pointee.ifa_next else { break }
            ptr = next
        }
        return (upload, download)
    }
}
