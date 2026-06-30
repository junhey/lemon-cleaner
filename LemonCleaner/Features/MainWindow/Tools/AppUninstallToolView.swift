import SwiftUI

struct AppUninstallToolView: View {
    @StateObject private var service = AppUninstallService()
    @State private var confirmApp: AppBundleInfo?
    @State private var message: String?

    var body: some View {
        VStack {
            HStack {
                Text("\(service.apps.count) applications")
                    .font(.headline)
                Spacer()
                Button("Refresh") { Task { await service.scan() } }
            }
            .padding()

            List(service.apps) { app in
                HStack {
                    VStack(alignment: .leading) {
                        Text(app.name)
                            .font(.system(size: 14, weight: .medium))
                        Text(app.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        if !app.relatedFiles.isEmpty {
                            Text("\(app.relatedFiles.count) related items")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.warningOrange)
                        }
                    }
                    Spacer()
                    Text(ByteFormatter.format(app.sizeBytes))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Uninstall", role: .destructive) {
                        confirmApp = app
                    }
                }
            }
        }
        .navigationTitle("App Uninstall")
        .confirmationDialog("Uninstall \(confirmApp?.name ?? "")?", isPresented: .init(
            get: { confirmApp != nil },
            set: { if !$0 { confirmApp = nil } }
        )) {
            Button("Uninstall", role: .destructive) {
                if let app = confirmApp {
                    Task {
                        do {
                            let freed = try await service.uninstall(app)
                            message = "Freed \(ByteFormatter.format(freed))"
                        } catch {
                            message = error.localizedDescription
                        }
                    }
                }
                confirmApp = nil
            }
            Button("Cancel", role: .cancel) { confirmApp = nil }
        }
        .alert("Result", isPresented: .init(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK") { message = nil }
        } message: {
            Text(message ?? "")
        }
        .task { await service.scan() }
    }
}

struct StartupItemsToolView: View {
    @StateObject private var service = StartupItemsService()
    @State private var confirmItem: StartupItem?

    var body: some View {
        VStack {
            HStack {
                Text("\(service.items.count) startup items")
                    .font(.headline)
                Spacer()
                Button("Refresh") { Task { await service.scan() } }
            }
            .padding()

            List(service.items) { item in
                HStack {
                    VStack(alignment: .leading) {
                        Text(item.name)
                        Text(item.source)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Remove", role: .destructive) {
                        confirmItem = item
                    }
                }
            }
        }
        .navigationTitle("Startup Items")
        .confirmationDialog("Remove startup item?", isPresented: .init(
            get: { confirmItem != nil },
            set: { if !$0 { confirmItem = nil } }
        )) {
            Button("Remove", role: .destructive) {
                if let item = confirmItem {
                    Task { try? await service.remove(item) }
                }
                confirmItem = nil
            }
            Button("Cancel", role: .cancel) { confirmItem = nil }
        }
        .task { await service.scan() }
    }
}

struct DiskAnalyzerToolView: View {
    @StateObject private var service = DiskAnalyzerService()
    @State private var currentPath = NSHomeDirectory()

    var body: some View {
        VStack {
            HStack {
                Text(currentPath)
                    .font(.caption)
                    .lineLimit(1)
                Spacer()
                if currentPath != NSHomeDirectory() {
                    Button("Back to Home") {
                        currentPath = NSHomeDirectory()
                        Task { await service.analyze(path: currentPath) }
                    }
                }
                Button("Refresh") {
                    Task { await service.analyze(path: currentPath) }
                }
            }
            .padding()

            List(service.directories) { dir in
                Button {
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue {
                        currentPath = dir.path
                        Task { await service.analyze(path: currentPath) }
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder")
                        Text(dir.name)
                        Spacer()
                        Text(ByteFormatter.format(dir.sizeBytes))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("Disk Analyzer")
        .task { await service.analyze(path: currentPath) }
    }
}

struct LemonLabToolView: View {
    private let links: [(String, String)] = [
        ("Lemon Cleaner on GitHub", "https://github.com/junhey/lemon-cleaner"),
        ("Homebrew", "https://brew.sh"),
        ("AppCleaner", "https://freemacsoft.net/appcleaner/"),
        ("OnyX", "https://www.titanium-software.fr/en/onyx.html"),
    ]

    var body: some View {
        List {
            Section("Discover more free Apps") {
                ForEach(links, id: \.0) { name, url in
                    Button(name) {
                        if let u = URL(string: url) {
                            NSWorkspace.shared.open(u)
                        }
                    }
                }
            }
        }
        .navigationTitle("Lemon Lab")
    }
}
