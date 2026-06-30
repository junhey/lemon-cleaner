import SwiftUI

struct FreeUpTabView: View {
    @EnvironmentObject private var monitor: SystemMonitorService
    @ObservedObject var viewModel: PopupPanelViewModel

    private var recoverableBytes: Int64 {
        viewModel.diskScan.result?.totalBytes ?? 0
    }

    private var memoryPercent: Double {
        monitor.metrics.memoryUsage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                recoverableSection
                Divider().padding(.horizontal, 16)
                memorySection
                ProcessListView(
                    apps: viewModel.processMemory.apps,
                    memoryPercent: memoryPercent
                )
            }
        }
    }

    private var recoverableSection: some View {
        HStack(spacing: 12) {
            HexagonLogo(size: 48)
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.diskScan.isScanning {
                    Text("Scanning…")
                        .font(.system(size: 18, weight: .bold))
                    ProgressView(value: viewModel.diskScan.progress)
                        .frame(width: 120)
                } else {
                    Text(ByteFormatter.format(recoverableBytes))
                        .font(.system(size: 20, weight: .bold))
                    Text("can be recovered")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            PrimaryButton(title: "Clean", color: AppTheme.cleanGreen) {
                viewModel.showCleanConfirm = true
            }
            .disabled(viewModel.diskScan.isScanning || recoverableBytes == 0 || viewModel.isCleaning)
        }
        .padding(16)
    }

    private var memorySection: some View {
        HStack {
            Image(systemName: "memorychip")
                .foregroundStyle(.secondary)
            Text("Memory usage")
                .font(.system(size: 13))
            Text(ByteFormatter.formatPercent(memoryPercent))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(memoryPercent > 70 ? AppTheme.warningOrange : .primary)
            Spacer()
            if viewModel.processMemory.isReleasing {
                ProgressView().controlSize(.small)
            } else {
                LinkButton(title: "Release") {
                    Task { await viewModel.releaseMemory() }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
