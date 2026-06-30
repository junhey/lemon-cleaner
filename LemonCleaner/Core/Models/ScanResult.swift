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

enum DuplicateGroup: Identifiable {
    case group(id: String, items: [ScanItem])

    var id: String {
        switch self {
        case .group(let id, _): return id
        }
    }

    var items: [ScanItem] {
        switch self {
        case .group(_, let items): return items
        }
    }

    var wastedBytes: Int64 {
        let sizes = items.map(\.sizeBytes)
        guard let max = sizes.max(), sizes.count > 1 else { return 0 }
        return max * Int64(sizes.count - 1)
    }
}

struct PhotoGroup: Identifiable {
    let id: String
    let items: [ScanItem]
}

struct StartupItem: Identifiable {
    let id: String
    let name: String
    let path: String
    let isEnabled: Bool
    let source: String
}

struct AppBundleInfo: Identifiable {
    let id: String
    let name: String
    let path: String
    let bundleIdentifier: String
    let sizeBytes: Int64
    let relatedFiles: [ScanItem]
}

struct DiskDirectorySize: Identifiable {
    let id: String
    let name: String
    let path: String
    let sizeBytes: Int64
}
