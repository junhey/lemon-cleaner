import Foundation
import CryptoKit

// MARK: - Large File Scanner

final class LargeFileScanner: ScanningService {
    private let thresholdBytes: Int64
    private let rootPath: String

    init(thresholdMB: Int = 50, scanFullDisk: Bool = false) {
        thresholdBytes = Int64(thresholdMB) * 1024 * 1024
        rootPath = scanFullDisk ? "/" : NSHomeDirectory()
    }

    func scan(progress: @escaping (Double) -> Void) async throws -> ScanResult {
        try await Task.detached(priority: .utility) {
            var items: [ScanItem] = []
            let fm = FileManager.default
            let root = URL(fileURLWithPath: self.rootPath, isDirectory: true)
            guard let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                return ScanResult(categories: [], scannedAt: Date())
            }

            var count = 0
            let excluded = ["/System", "/private/var/vm", "/dev", "/Volumes/.timemachine"]
            for case let url as URL in enumerator {
                if excluded.contains(where: { url.path.hasPrefix($0) }) {
                    enumerator.skipDescendants()
                    continue
                }
                count += 1
                if count % 200 == 0 { progress(min(0.99, Double(count) / 10000)) }
                guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                      values.isDirectory != true else { continue }
                let size = Int64(values.fileSize ?? 0)
                guard size >= self.thresholdBytes else { continue }
                items.append(ScanItem(id: url.path, path: url.path, name: url.lastPathComponent, sizeBytes: size, category: "Large Files"))
            }
            progress(1)
            items.sort { $0.sizeBytes > $1.sizeBytes }
            let category = ScanCategory(id: "large", name: "Large Files", items: items)
            return ScanResult(categories: [category], scannedAt: Date())
        }.value
    }

    func clean(items: [ScanItem]) async throws -> Int64 {
        try await CacheCleanService().clean(items: items)
    }
}

// MARK: - Duplicate File Scanner

final class DuplicateFileScanner: ScanningService {
    private let rootPath: String

    init(scanFullDisk: Bool = false) {
        rootPath = scanFullDisk ? NSHomeDirectory() : NSHomeDirectory()
    }

    func scan(progress: @escaping (Double) -> Void) async throws -> ScanResult {
        try await Task.detached(priority: .utility) {
            var sizeMap: [Int64: [URL]] = [:]
            let fm = FileManager.default
            let root = URL(fileURLWithPath: self.rootPath, isDirectory: true)
            guard let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                return ScanResult(categories: [], scannedAt: Date())
            }

            var count = 0
            for case let url as URL in enumerator {
                count += 1
                if count % 300 == 0 { progress(min(0.5, Double(count) / 20000)) }
                guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                      values.isDirectory != true else { continue }
                let size = Int64(values.fileSize ?? 0)
                guard size > 1024 else { continue }
                sizeMap[size, default: []].append(url)
            }

            var duplicateItems: [ScanItem] = []
            let candidateGroups = sizeMap.values.filter { $0.count > 1 }
            let totalGroups = max(1, candidateGroups.count)
            for (index, group) in candidateGroups.enumerated() {
                progress(0.5 + Double(index) / Double(totalGroups) * 0.5)
                let hashes = Self.hashGroup(urls: group)
                for (_, urls) in hashes where urls.count > 1 {
                    for url in urls.dropFirst() {
                        let size = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                        duplicateItems.append(ScanItem(id: url.path, path: url.path, name: url.lastPathComponent, sizeBytes: size, category: "Duplicates"))
                    }
                }
            }
            progress(1)
            let category = ScanCategory(id: "duplicates", name: "Duplicate Files", items: duplicateItems)
            return ScanResult(categories: [category], scannedAt: Date())
        }.value
    }

    func clean(items: [ScanItem]) async throws -> Int64 {
        try await CacheCleanService().clean(items: items)
    }

    private static func hashGroup(urls: [URL]) -> [String: [URL]] {
        var map: [String: [URL]] = [:]
        for url in urls {
            guard let hash = fileHash(url: url) else { continue }
            map[hash, default: []].append(url)
        }
        return map
    }

    private static func fileHash(url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: 65536)
            if data.isEmpty { return false }
            hasher.update(data: data)
            return true
        }) {}
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Privacy Clean Service

final class PrivacyCleanService: ScanningService {
    private let browserPaths: [(name: String, paths: [String])] = {
        let home = NSHomeDirectory()
        return [
            ("Safari", ["\(home)/Library/Caches/com.apple.Safari", "\(home)/Library/Safari/LocalStorage"]),
            ("Chrome", ["\(home)/Library/Caches/Google/Chrome", "\(home)/Library/Application Support/Google/Chrome/Default/Cache"]),
            ("Firefox", ["\(home)/Library/Caches/Firefox", "\(home)/Library/Application Support/Firefox/Profiles"]),
            ("Edge", ["\(home)/Library/Caches/Microsoft Edge", "\(home)/Library/Application Support/Microsoft Edge/Default/Cache"]),
        ]
    }()

    func scan(progress: @escaping (Double) -> Void) async throws -> ScanResult {
        try await Task.detached(priority: .utility) {
            var categories: [ScanCategory] = []
            for (index, browser) in self.browserPaths.enumerated() {
                progress(Double(index) / Double(self.browserPaths.count))
                var items: [ScanItem] = []
                for path in browser.paths {
                    let size = Self.directorySize(path: path)
                    guard size > 0 else { continue }
                    items.append(ScanItem(id: path, path: path, name: (path as NSString).lastPathComponent, sizeBytes: size, category: browser.name))
                }
                if !items.isEmpty {
                    categories.append(ScanCategory(id: browser.name, name: browser.name, items: items))
                }
            }
            progress(1)
            return ScanResult(categories: categories, scannedAt: Date())
        }.value
    }

    func clean(items: [ScanItem]) async throws -> Int64 {
        try await CacheCleanService().clean(items: items)
    }

    private static func directorySize(path: String) -> Int64 {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }
        if !isDir.boolValue {
            return Int64((try? fm.attributesOfItem(atPath: path)[.size] as? NSNumber)?.int64Value ?? 0)
        }
        guard let enumerator = fm.enumerator(atPath: path) else { return 0 }
        var total: Int64 = 0
        for case let file as String in enumerator {
            let full = (path as NSString).appendingPathComponent(file)
            total += Int64((try? fm.attributesOfItem(atPath: full)[.size] as? NSNumber)?.int64Value ?? 0)
        }
        return total
    }
}

// MARK: - Disk Analyzer Service

final class DiskAnalyzerService: ObservableObject {
    @Published private(set) var directories: [DiskDirectorySize] = []

    func analyze(path: String? = nil) async {
        let target = path ?? NSHomeDirectory()
        let sizes = await Task.detached(priority: .utility) {
            Self.topLevelSizes(path: target)
        }.value
        await MainActor.run { directories = sizes }
    }

    private static func topLevelSizes(path: String) -> [DiskDirectorySize] {
        let fm = FileManager.default
        guard let contents = try? fm.contentsOfDirectory(atPath: path) else { return [] }
        return contents.map { name in
            let full = (path as NSString).appendingPathComponent(name)
            let size = directorySize(path: full)
            return DiskDirectorySize(id: full, name: name, path: full, sizeBytes: size)
        }
        .sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private static func directorySize(path: String) -> Int64 {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: path, isDirectory: &isDir) else { return 0 }
        if !isDir.boolValue {
            return Int64((try? fm.attributesOfItem(atPath: path)[.size] as? NSNumber)?.int64Value ?? 0)
        }
        guard let enumerator = fm.enumerator(atPath: path) else { return 0 }
        var total: Int64 = 0
        for case let file as String in enumerator {
            let full = (path as NSString).appendingPathComponent(file)
            total += Int64((try? fm.attributesOfItem(atPath: full)[.size] as? NSNumber)?.int64Value ?? 0)
        }
        return total
    }
}
