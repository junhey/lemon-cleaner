import SwiftUI

struct MainDashboardView: View {
    @State private var selectedTool: ToolKind?
    @State private var isScanning = false
    @ObservedObject private var settings = UserSettings.shared

    var body: some View {
        NavigationSplitView {
            leftPanel
        } detail: {
            if let tool = selectedTool {
                toolDetail(for: tool)
            } else {
                toolGrid
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    private var leftPanel: some View {
        VStack(spacing: 24) {
            Spacer()
            HexagonLogo(size: 140)
            VStack(spacing: 8) {
                Text("Know your Mac better")
                    .font(.system(size: 24, weight: .bold))
                Text("Welcome to Lemon Cleaner")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            PrimaryButton(title: isScanning ? "Scanning…" : "Scan", color: AppTheme.cleanGreen) {
                runQuickScan()
            }
            .disabled(isScanning)
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "circle.grid.2x2.fill")
                    .foregroundStyle(AppTheme.lemonAccent.opacity(0.5))
            }
        }
        .padding(32)
        .frame(minWidth: 320)
        .background(AppTheme.sidebarBackground)
    }

    private var toolGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(ToolKind.allCases) { tool in
                    ToolCard(tool: tool) {
                        selectedTool = tool
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Lemon Cleaner")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    if let url = URL(string: "https://github.com/junhey/lemon-cleaner/issues") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("Share valuable suggestions", systemImage: "ellipsis.bubble")
                }
            }
        }
    }

    @ViewBuilder
    private func toolDetail(for tool: ToolKind) -> some View {
        switch tool {
        case .largeFile:
            LargeFileToolView(scanFullDisk: settings.scanFullDisk, thresholdMB: settings.largeFileThresholdMB)
        case .duplicateFile:
            DuplicateFileToolView(scanFullDisk: settings.scanFullDisk)
        case .similarPhotos:
            SimilarPhotoToolView()
        case .appUninstall:
            AppUninstallToolView()
        case .privacyClean:
            PrivacyCleanToolView()
        case .startupItems:
            StartupItemsToolView()
        case .diskAnalyzer:
            DiskAnalyzerToolView()
        case .lemonLab:
            LemonLabToolView()
        }
    }

    private func runQuickScan() {
        isScanning = true
        Task {
            let diskScan = DiskScanService()
            await diskScan.scan()
            isScanning = false
            selectedTool = .largeFile
        }
    }
}

enum ToolKind: String, CaseIterable, Identifiable {
    case largeFile, duplicateFile, similarPhotos, appUninstall
    case privacyClean, startupItems, diskAnalyzer, lemonLab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .largeFile: return "Large File"
        case .duplicateFile: return "Duplicate File"
        case .similarPhotos: return "Similar Photos"
        case .appUninstall: return "App Uninstall"
        case .privacyClean: return "Privacy Clean"
        case .startupItems: return "Startup Items"
        case .diskAnalyzer: return "Disk Analyzer"
        case .lemonLab: return "Lemon Lab"
        }
    }

    var description: String {
        switch self {
        case .largeFile: return "Find and delete files larger than 50MB"
        case .duplicateFile: return "Retrieve and delete duplicate files"
        case .similarPhotos: return "Find and compare similar photos"
        case .appUninstall: return "Remove applications and associated files"
        case .privacyClean: return "Wash browser tracks"
        case .startupItems: return "Stop apps or services running at startup"
        case .diskAnalyzer: return "In-depth analysis of disk space"
        case .lemonLab: return "Discover more free Apps"
        }
    }

    var iconName: String {
        switch self {
        case .largeFile: return "folder"
        case .duplicateFile: return "square.on.square.dashed"
        case .similarPhotos: return "photo.on.rectangle"
        case .appUninstall: return "trash"
        case .privacyClean: return "shield.lefthalf.filled"
        case .startupItems: return "power"
        case .diskAnalyzer: return "internaldrive"
        case .lemonLab: return "square.grid.2x2"
        }
    }
}

struct ToolCard: View {
    let tool: ToolKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: tool.iconName)
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
                Text(tool.title)
                    .font(.system(size: 15, weight: .semibold))
                Text(tool.description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
}
