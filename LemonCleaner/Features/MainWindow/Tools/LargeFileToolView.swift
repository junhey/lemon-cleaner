import SwiftUI

struct LargeFileToolView: View {
    let scanFullDisk: Bool
    let thresholdMB: Int
    @StateObject private var viewModel: ToolScanViewModel

    init(scanFullDisk: Bool, thresholdMB: Int) {
        self.scanFullDisk = scanFullDisk
        self.thresholdMB = thresholdMB
        _viewModel = StateObject(wrappedValue: ToolScanViewModel(
            scanner: LargeFileScanner(thresholdMB: thresholdMB, scanFullDisk: scanFullDisk)
        ))
    }

    var body: some View {
        ScanResultListView(
            result: viewModel.result,
            isScanning: viewModel.isScanning,
            progress: viewModel.progress,
            selectedItems: $viewModel.selectedItems,
            onScan: { Task { await viewModel.scan() } },
            onClean: { Task { await viewModel.clean() } }
        )
        .navigationTitle("Large File")
        .alert("Result", isPresented: .init(
            get: { viewModel.message != nil },
            set: { if !$0 { viewModel.message = nil } }
        )) {
            Button("OK") { viewModel.message = nil }
        } message: {
            Text(viewModel.message ?? "")
        }
        .task { await viewModel.scan() }
    }
}

struct DuplicateFileToolView: View {
    @StateObject private var viewModel: ToolScanViewModel

    init(scanFullDisk: Bool) {
        _viewModel = StateObject(wrappedValue: ToolScanViewModel(
            scanner: DuplicateFileScanner(scanFullDisk: scanFullDisk)
        ))
    }

    var body: some View {
        ScanResultListView(
            result: viewModel.result,
            isScanning: viewModel.isScanning,
            progress: viewModel.progress,
            selectedItems: $viewModel.selectedItems,
            onScan: { Task { await viewModel.scan() } },
            onClean: { Task { await viewModel.clean() } }
        )
        .navigationTitle("Duplicate File")
        .task { await viewModel.scan() }
    }
}

struct PrivacyCleanToolView: View {
    @StateObject private var viewModel = ToolScanViewModel(scanner: PrivacyCleanService())

    var body: some View {
        ScanResultListView(
            result: viewModel.result,
            isScanning: viewModel.isScanning,
            progress: viewModel.progress,
            selectedItems: $viewModel.selectedItems,
            onScan: { Task { await viewModel.scan() } },
            onClean: { Task { await viewModel.clean() } }
        )
        .navigationTitle("Privacy Clean")
        .task { await viewModel.scan() }
    }
}
