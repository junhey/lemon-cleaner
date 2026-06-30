import Foundation

@MainActor
final class DiskScanService: ObservableObject {
    @Published private(set) var result: ScanResult?
    @Published private(set) var isScanning = false
    @Published private(set) var progress: Double = 0

    private static let scanTargets: [(name: String, path: String)] = {
        let home = NSHomeDirectory()
        return [
            ("Caches", "\(home)/Library/Caches"),
            ("Logs", "\(home)/Library/Logs"),
            ("Trash", "\(home)/.Trash"),
            ("Crash Reports", "\(home)/Library/Application Support/CrashReporter"),
            ("Temp", NSTemporaryDirectory()),
        ]
    }()

    func scan() async {
        isScanning = true
        progress = 0
        defer {
            isScanning = false
            progress = 1
        }

        let targets = Self.scanTargets
        let scanned = await Task.detached(priority: .utility) {
            Self.performScan(targets: targets) { value in
                Task { @MainActor in
                    self.progress = value
                }
            }
        }.value

        result = scanned
    }

    nonisolated private static func performScan(
        targets: [(name: String, path: String)],
        onProgress: @escaping (Double) -> Void
    ) -> ScanResult {
        var categories: [ScanCategory] = []
        let fm = FileManager.default
        for (index, target) in targets.enumerated() {
            onProgress(Double(index) / Double(targets.count))
            var items: [ScanItem] = []
            guard fm.fileExists(atPath: target.path) else { continue }
            let url = URL(fileURLWithPath: target.path, isDirectory: true)
            if target.name == "Trash" || target.name == "Temp" {
                items = scanFlatDirectory(url: url, category: target.name, fm: fm)
            } else {
                items = scanDirectory(url: url, category: target.name, fm: fm, maxDepth: 3)
            }
            if !items.isEmpty {
                categories.append(ScanCategory(id: target.name, name: target.name, items: items))
            }
        }
        onProgress(1)
        return ScanResult(categories: categories, scannedAt: Date())
    }

    nonisolated private static func scanFlatDirectory(url: URL, category: String, fm: FileManager) -> [ScanItem] {
        guard let contents = try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else {
            return []
        }
        return contents.compactMap { itemURL in
            guard let values = try? itemURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]) else { return nil }
            let size: Int64
            if values.isDirectory == true {
                size = directorySize(url: itemURL, fm: fm)
            } else {
                size = Int64(values.fileSize ?? 0)
            }
            guard size > 0 else { return nil }
            return ScanItem(id: itemURL.path, path: itemURL.path, name: itemURL.lastPathComponent, sizeBytes: size, category: category)
        }
    }

    nonisolated private static func scanDirectory(url: URL, category: String, fm: FileManager, maxDepth: Int) -> [ScanItem] {
        var items: [ScanItem] = []
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return items }

        for case let fileURL as URL in enumerator {
            let depth = fileURL.pathComponents.count - url.pathComponents.count
            if depth > maxDepth {
                enumerator.skipDescendants()
                continue
            }
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                  values.isDirectory != true else { continue }
            let size = Int64(values.fileSize ?? 0)
            guard size > 0 else { continue }
            items.append(ScanItem(id: fileURL.path, path: fileURL.path, name: fileURL.lastPathComponent, sizeBytes: size, category: category))
        }
        return items
    }

    nonisolated private static func directorySize(url: URL, fm: FileManager) -> Int64 {
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}

@MainActor
final class CacheCleanService {
    func clean(items: [ScanItem]) async throws -> Int64 {
        try await Task.detached(priority: .utility) {
            let fm = FileManager.default
            var freed: Int64 = 0
            for item in items where item.isSelected {
                let url = URL(fileURLWithPath: item.path)
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: item.path, isDirectory: &isDir) else { continue }
                do {
                    try fm.trashItem(at: url, resultingItemURL: nil)
                    freed += item.sizeBytes
                } catch {
                    continue
                }
            }
            return freed
        }.value
    }
}
