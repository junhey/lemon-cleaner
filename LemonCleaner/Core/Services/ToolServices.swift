import Foundation
import CryptoKit
import ImageIO
import AppKit

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

// MARK: - Similar Photo Scanner

final class SimilarPhotoScanner: ScanningService {
    func scan(progress: @escaping (Double) -> Void) async throws -> ScanResult {
        try await Task.detached(priority: .utility) {
            let fm = FileManager.default
            let pictures = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Pictures")
            var photos: [(url: URL, hash: UInt64)] = []
            guard let enumerator = fm.enumerator(at: pictures, includingPropertiesForKeys: nil) else {
                return ScanResult(categories: [], scannedAt: Date())
            }
            var count = 0
            for case let url as URL in enumerator {
                let ext = url.pathExtension.lowercased()
                guard ["jpg", "jpeg", "png", "heic", "webp"].contains(ext) else { continue }
                count += 1
                if count % 20 == 0 { progress(min(0.8, Double(count) / 500)) }
                if let hash = Self.aHash(url: url) {
                    photos.append((url, hash))
                }
            }

            var groups: [[URL]] = []
            var used = Set<String>()
            for i in 0..<photos.count {
                let a = photos[i]
                if used.contains(a.url.path) { continue }
                var group = [a.url]
                used.insert(a.url.path)
                for j in (i + 1)..<photos.count {
                    let b = photos[j]
                    if used.contains(b.url.path) { continue }
                    if Self.hammingDistance(a.hash, b.hash) <= 5 {
                        group.append(b.url)
                        used.insert(b.url.path)
                    }
                }
                if group.count > 1 { groups.append(group) }
            }

            var items: [ScanItem] = []
            for group in groups {
                for url in group.dropFirst() {
                    let size = Int64((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0)
                    items.append(ScanItem(id: url.path, path: url.path, name: url.lastPathComponent, sizeBytes: size, category: "Similar Photos"))
                }
            }
            progress(1)
            return ScanResult(categories: [ScanCategory(id: "photos", name: "Similar Photos", items: items)], scannedAt: Date())
        }.value
    }

    func clean(items: [ScanItem]) async throws -> Int64 {
        try await CacheCleanService().clean(items: items)
    }

    private static func aHash(url: URL) -> UInt64? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceThumbnailMaxPixelSize: 8,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
              ] as CFDictionary) else { return nil }

        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else { return nil }

        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var gray: [UInt8] = []
        gray.reserveCapacity(width * height)
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let r = Double(pixels[i])
            let g = Double(pixels[i + 1])
            let b = Double(pixels[i + 2])
            gray.append(UInt8((r * 0.299 + g * 0.587 + b * 0.114).rounded()))
        }
        let avg = Double(gray.reduce(0) { $0 + Int($1) }) / Double(gray.count)
        var hash: UInt64 = 0
        for (index, value) in gray.enumerated() {
            if Double(value) >= avg {
                hash |= (1 << UInt64(index % 64))
            }
        }
        return hash
    }

    private static func hammingDistance(_ a: UInt64, _ b: UInt64) -> Int {
        (a ^ b).nonzeroBitCount
    }
}

// MARK: - App Uninstall Service

final class AppUninstallService: ObservableObject {
    @Published private(set) var apps: [AppBundleInfo] = []

    func scan() async {
        let found = await Task.detached(priority: .utility) {
            Self.findApps()
        }.value
        await MainActor.run { apps = found }
    }

    func uninstall(_ app: AppBundleInfo) async throws -> Int64 {
        try await Task.detached(priority: .utility) {
            let fm = FileManager.default
            var freed: Int64 = app.sizeBytes
            for item in app.relatedFiles { freed += item.sizeBytes }

            try fm.trashItem(at: URL(fileURLWithPath: app.path), resultingItemURL: nil)
            for item in app.relatedFiles {
                try? fm.trashItem(at: URL(fileURLWithPath: item.path), resultingItemURL: nil)
            }
            return freed
        }.value
    }

    private static func findApps() -> [AppBundleInfo] {
        let paths = ["/Applications", NSHomeDirectory() + "/Applications"]
        var apps: [AppBundleInfo] = []
        let fm = FileManager.default
        for base in paths {
            guard let contents = try? fm.contentsOfDirectory(atPath: base) else { continue }
            for name in contents where name.hasSuffix(".app") {
                let path = (base as NSString).appendingPathComponent(name)
                guard let bundle = Bundle(path: path),
                      let bundleID = bundle.bundleIdentifier else { continue }
                let appName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? name
                let size = directorySize(path: path)
                let related = relatedFiles(bundleID: bundleID)
                apps.append(AppBundleInfo(
                    id: bundleID,
                    name: appName,
                    path: path,
                    bundleIdentifier: bundleID,
                    sizeBytes: size,
                    relatedFiles: related
                ))
            }
        }
        return apps.sorted { $0.sizeBytes > $1.sizeBytes }
    }

    private static func relatedFiles(bundleID: String) -> [ScanItem] {
        let home = NSHomeDirectory()
        let candidates = [
            "\(home)/Library/Application Support/\(bundleID)",
            "\(home)/Library/Caches/\(bundleID)",
            "\(home)/Library/Preferences/\(bundleID).plist",
            "\(home)/Library/Containers/\(bundleID)",
        ]
        var items: [ScanItem] = []
        let fm = FileManager.default
        for path in candidates where fm.fileExists(atPath: path) {
            let size = directorySize(path: path)
            items.append(ScanItem(id: path, path: path, name: (path as NSString).lastPathComponent, sizeBytes: size, category: "Related"))
        }
        return items
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

// MARK: - Startup Items Service

final class StartupItemsService: ObservableObject {
    @Published private(set) var items: [StartupItem] = []

    func scan() async {
        let found = await Task.detached(priority: .utility) {
            Self.loadItems()
        }.value
        await MainActor.run { items = found }
    }

    func remove(_ item: StartupItem) async throws {
        try await Task.detached(priority: .utility) {
            try FileManager.default.trashItem(at: URL(fileURLWithPath: item.path), resultingItemURL: nil)
        }.value
        await scan()
    }

    private static func loadItems() -> [StartupItem] {
        var results: [StartupItem] = []
        let paths = [
            ("User LaunchAgents", NSHomeDirectory() + "/Library/LaunchAgents"),
            ("System LaunchAgents", "/Library/LaunchAgents"),
        ]
        let fm = FileManager.default
        for (source, path) in paths {
            guard let files = try? fm.contentsOfDirectory(atPath: path) else { continue }
            for file in files where file.hasSuffix(".plist") {
                let full = (path as NSString).appendingPathComponent(file)
                results.append(StartupItem(id: full, name: file, path: full, isEnabled: true, source: source))
            }
        }
        return results
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
