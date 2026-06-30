import SwiftUI

struct MainDashboardView: View {
    @State private var selectedTool: ToolKind?
    @ObservedObject private var settings = UserSettings.shared

    var body: some View {
        NavigationSplitView {
            brandingPanel
        } detail: {
            if let tool = selectedTool {
                toolDetail(for: tool)
            } else {
                toolGrid
            }
        }
        .frame(minWidth: 800, minHeight: 520)
    }

    private var brandingPanel: some View {
        VStack(spacing: 16) {
            Spacer()
            HexagonLogo(size: 88)
            VStack(spacing: 4) {
                Text("Airy")
                    .font(.system(size: 26, weight: .bold))
                Text("Lightweight Mac care")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(28)
        .frame(minWidth: 220)
        .background(AppTheme.sidebarBackground)
    }

    private var toolGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(ToolKind.allCases) { tool in
                    ToolCard(tool: tool) {
                        selectedTool = tool
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle("Airy")
    }

    @ViewBuilder
    private func toolDetail(for tool: ToolKind) -> some View {
        switch tool {
        case .largeFile:
            LargeFileToolView(scanFullDisk: settings.scanFullDisk, thresholdMB: settings.largeFileThresholdMB)
        case .duplicateFile:
            DuplicateFileToolView(scanFullDisk: settings.scanFullDisk)
        case .privacyClean:
            PrivacyCleanToolView()
        case .diskAnalyzer:
            DiskAnalyzerToolView()
        }
    }
}

enum ToolKind: String, CaseIterable, Identifiable {
    case largeFile, duplicateFile, privacyClean, diskAnalyzer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .largeFile: return "Large File"
        case .duplicateFile: return "Duplicate"
        case .privacyClean: return "Privacy Clean"
        case .diskAnalyzer: return "Disk Analyzer"
        }
    }

    var description: String {
        switch self {
        case .largeFile: return "Find and delete files larger than 50MB"
        case .duplicateFile: return "Retrieve and delete duplicate files"
        case .privacyClean: return "Wash browser tracks"
        case .diskAnalyzer: return "In-depth analysis of disk space"
        }
    }

    var iconName: String {
        switch self {
        case .largeFile: return "folder"
        case .duplicateFile: return "square.on.square.dashed"
        case .privacyClean: return "shield.lefthalf.filled"
        case .diskAnalyzer: return "internaldrive"
        }
    }
}

struct ToolCard: View {
    let tool: ToolKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: tool.iconName)
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                Text(tool.title)
                    .font(.system(size: 14, weight: .semibold))
                Text(tool.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
}
