import AppKit

struct AppMemoryUsage: Identifiable, Equatable {
    let id: String
    let name: String
    let bundleIdentifier: String?
    let memoryBytes: UInt64
    let icon: NSImage?

    static func == (lhs: AppMemoryUsage, rhs: AppMemoryUsage) -> Bool {
        lhs.id == rhs.id && lhs.memoryBytes == rhs.memoryBytes
    }
}
