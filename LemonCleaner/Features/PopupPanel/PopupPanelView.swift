import SwiftUI

@MainActor
final class PopupPanelViewModel: ObservableObject {
    @Published var selectedTab: PopupTab = .freeUp
    @Published var showCleanConfirm = false
    @Published var showCleanResult = false
    @Published var cleanResultMessage = ""
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

    func clean() async {
        guard let result = diskScan.result else { return }
        isCleaning = true
        defer { isCleaning = false }
        do {
            let freed = try await cacheClean.clean(items: result.allItems)
            cleanResultMessage = "Recovered \(ByteFormatter.format(freed))"
            showCleanResult = true
            await diskScan.scan()
        } catch {
            cleanResultMessage = "Clean failed: \(error.localizedDescription)"
            showCleanResult = true
        }
    }

    func releaseMemory() async {
        await processMemory.releaseMemory()
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
        .alert("Clean Complete", isPresented: $viewModel.showCleanResult) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.cleanResultMessage)
        }
        .confirmationDialog("Clean recoverable files?", isPresented: $viewModel.showCleanConfirm) {
            Button("Clean", role: .destructive) {
                Task { await viewModel.clean() }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
