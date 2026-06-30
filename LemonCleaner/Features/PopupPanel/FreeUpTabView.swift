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
        VStack(spacing: 0) {
            recoverableSection
            Divider().opacity(0.35)
            memorySection
            ProcessListView(
                apps: viewModel.processMemory.apps,
                memoryPercent: memoryPercent
            )
        }
    }

    private var recoverableSection: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                if viewModel.diskScan.isScanning {
                    Text("Scanning…")
                        .font(.system(size: 15, weight: .semibold))
                    HStack(spacing: 6) {
                        ProgressView(value: viewModel.diskScan.progress)
                            .frame(width: 80)
                        Text("\(Int(viewModel.diskScan.progress * 100))%")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } else if recoverableBytes == 0 {
                    Text("Nothing to clean")
                        .font(.system(size: 16, weight: .bold))
                    Text("Your Mac looks tidy")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    Text(ByteFormatter.format(recoverableBytes))
                        .font(.system(size: 16, weight: .bold))
                    Text("can be recovered")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            PrimaryButton(title: "Clean", color: AppTheme.cleanGreen) {
                viewModel.showCleanConfirm = true
            }
            .disabled(viewModel.diskScan.isScanning || recoverableBytes == 0 || viewModel.isCleaning)
        }
        .padding(.horizontal, AppTheme.panelHorizontalPadding)
        .padding(.vertical, 10)
    }

    private var memorySection: some View {
        HStack {
            Text("Memory")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(ByteFormatter.formatPercent(memoryPercent))
                .font(.system(size: 12, weight: .semibold))
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
        .padding(.horizontal, AppTheme.panelHorizontalPadding)
        .padding(.vertical, 6)
    }
}
