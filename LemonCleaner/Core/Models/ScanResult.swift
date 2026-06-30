import Foundation

struct ScanItem: Identifiable, Hashable {
    let id: String
    let path: String
    let name: String
    let sizeBytes: Int64
    let category: String
    var isSelected: Bool = true
}

struct ScanCategory: Identifiable {
    let id: String
    let name: String
    let items: [ScanItem]
    var totalBytes: Int64 { items.reduce(0) { $0 + $1.sizeBytes } }
}

struct ScanResult {
    let categories: [ScanCategory]
    let scannedAt: Date

    var totalBytes: Int64 {
        categories.reduce(0) { $0 + $1.totalBytes }
    }

    var allItems: [ScanItem] {
        categories.flatMap(\.items)
    }
}

protocol ScanningService {
    func scan(progress: @escaping (Double) -> Void) async throws -> ScanResult
    func clean(items: [ScanItem]) async throws -> Int64
}

struct DiskDirectorySize: Identifiable {
    let id: String
    let name: String
    let path: String
    let sizeBytes: Int64
}
