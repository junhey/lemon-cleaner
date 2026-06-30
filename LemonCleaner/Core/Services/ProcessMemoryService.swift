import AppKit
import Foundation
import Darwin

@MainActor
final class ProcessMemoryService: ObservableObject {
    @Published private(set) var apps: [AppMemoryUsage] = []
    @Published private(set) var isReleasing = false
    @Published var lastReleaseMessage: String?

    func refresh() {
        apps = ProcessMemoryReader.topApps(limit: 8)
    }

    func releaseMemory() async {
        isReleasing = true
        defer { isReleasing = false }

        let purgePath = "/usr/sbin/purge"
        if FileManager.default.isExecutableFile(atPath: purgePath) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: purgePath)
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    lastReleaseMessage = "Inactive memory released."
                    refresh()
                    return
                }
            } catch {
                // fall through
            }
        }

        malloc_zone_pressure_relief(nil, 0)
        lastReleaseMessage = "Memory pressure relief applied."
        refresh()
    }
}

enum ProcessMemoryReader {
    static func topApps(limit: Int) -> [AppMemoryUsage] {
        let pids = allPIDs()
        var memoryByBundle: [String: (name: String, bytes: UInt64, path: String?)] = [:]

        for pid in pids {
            guard let info = processInfo(pid: pid) else { continue }
            let key = info.bundleID ?? info.name
            var entry = memoryByBundle[key] ?? (info.name, 0, info.bundlePath)
            entry.bytes &+= info.memory
            if info.memory > 0 { entry.name = info.name }
            if info.bundlePath != nil { entry.path = info.bundlePath }
            memoryByBundle[key] = entry
        }

        return memoryByBundle
            .map { key, value in
                let icon: NSImage?
                if let path = value.path {
                    icon = NSWorkspace.shared.icon(forFile: path)
                } else {
                    icon = NSImage(named: NSImage.applicationIconName)
                }
                return AppMemoryUsage(
                    id: key,
                    name: value.name,
                    bundleIdentifier: key.contains(".") ? key : nil,
                    memoryBytes: value.bytes,
                    icon: icon
                )
            }
            .sorted { $0.memoryBytes > $1.memoryBytes }
            .prefix(limit)
            .map { $0 }
    }

    private static func allPIDs() -> [pid_t] {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0]
        var bufferSize = 0
        sysctl(&mib, 4, nil, &bufferSize, nil, 0)
        let count = bufferSize / MemoryLayout<kinfo_proc>.size
        var procs = [kinfo_proc](repeating: kinfo_proc(), count: count)
        var size = bufferSize
        guard sysctl(&mib, 4, &procs, &size, nil, 0) == 0 else { return [] }
        return procs.map { $0.kp_proc.p_pid }
    }

    private static func runningApp(pid: pid_t) -> NSRunningApplication? {
        NSRunningApplication(processIdentifier: pid)
    }

    private static func processInfo(pid: pid_t) -> (name: String, bundleID: String?, bundlePath: String?, memory: UInt64)? {
        var info = proc_taskinfo()
        let size = MemoryLayout<proc_taskinfo>.size
        let result = proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, Int32(size))
        guard result == Int32(size) else { return nil }

        let memory = UInt64(info.pti_resident_size)
        guard memory > 0 else { return nil }

        let name = processName(pid: pid) ?? "Process \(pid)"
        let app = runningApp(pid: pid)
        return (name, app?.bundleIdentifier, app?.bundleURL?.path, memory)
    }

    private static func processName(pid: pid_t) -> String? {
        var name = [CChar](repeating: 0, count: 1024)
        guard proc_name(pid, &name, UInt32(name.count)) > 0 else { return nil }
        let raw = String(cString: name)
        if let app = runningApp(pid: pid) {
            return app.localizedName ?? raw
        }
        return raw
    }
}
