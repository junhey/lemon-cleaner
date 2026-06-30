import SwiftUI

@MainActor
final class PopupPanelViewModel: ObservableObject {
    @Published var selectedTab: PopupTab = .freeUp
    @Published var showCleanConfirm = false
    @Published var showCleanResult = false
    @Published var cleanResultBytes: Int64 = 0
    @Published var cleanResultFailed = false
    @Published var cleanResultError = ""
    @Published var showReleaseResult = false
    @Published var isCleaning = false

    let diskScan = DiskScanService()
    let processMemory = ProcessMemoryService()
    let cacheClean = CacheCleanService()

    func onAppear(monitor: SystemMonitorService) {
        monitor.start()
        Task {
            await diskScan.scan()
            processMemory.refresh()
        }
    }

    func startProcessRefresh() {
        processMemory.refresh()
    }

    func clean() async {
        guard let result = diskScan.result else { return }
        isCleaning = true
        defer { isCleaning = false }
        do {
            let freed = try await cacheClean.clean(items: result.allItems)
            cleanResultBytes = freed
            cleanResultFailed = false
            showCleanResult = true
            await diskScan.scan()
        } catch {
            cleanResultFailed = true
            cleanResultError = error.localizedDescription
            showCleanResult = true
        }
    }

    func releaseMemory() async {
        await processMemory.releaseMemory()
        showReleaseResult = true
    }
}

struct PopupPanelView: View {
    @EnvironmentObject private var monitor: SystemMonitorService
    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModel = PopupPanelViewModel()

    var body: some View {
        VStack(spacing: 0) {
            TabHeader(selectedTab: $viewModel.selectedTab)

            Group {
                switch viewModel.selectedTab {
                case .freeUp:
                    FreeUpTabView(viewModel: viewModel)
                case .system:
                    SystemTabView(monitor: monitor)
                }
            }
            .frame(maxHeight: .infinity)

            FooterBar(onLaunch: { openWindow(id: "main") })
        }
        .frame(width: AppTheme.panelWidth, height: AppTheme.panelHeight)
        .background(AppTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.panelCornerRadius, style: .continuous))
        .shadow(color: AppTheme.cardShadow, radius: 12, y: 4)
        .onAppear { viewModel.onAppear(monitor: monitor) }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(3))
                viewModel.startProcessRefresh()
            }
        }
        .alert(cleanAlertTitle, isPresented: $viewModel.showCleanResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cleanAlertMessage)
        }
        .alert("Memory Released", isPresented: $viewModel.showReleaseResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.processMemory.lastReleaseMessage ?? "Done.")
        }
        .confirmationDialog("Clean recoverable files?", isPresented: $viewModel.showCleanConfirm) {
            Button("Clean", role: .destructive) {
                Task { await viewModel.clean() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var cleanAlertTitle: String {
        viewModel.cleanResultFailed ? "Clean Failed" : ByteFormatter.format(viewModel.cleanResultBytes)
    }

    private var cleanAlertMessage: String {
        if viewModel.cleanResultFailed {
            return viewModel.cleanResultError
        }
        return "Files moved to Trash."
    }
}
