import SwiftUI

struct ScanResultListView: View {
    let result: ScanResult?
    let isScanning: Bool
    let progress: Double
    @Binding var selectedItems: Set<String>
    var onScan: () -> Void
    var onClean: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let result {
                    Text("\(ByteFormatter.format(result.totalBytes)) recoverable")
                        .font(.headline)
                } else {
                    Text("No scan results")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Scan", action: onScan)
                    .disabled(isScanning)
                Button("Clean Selected", role: .destructive, action: onClean)
                    .disabled(selectedItems.isEmpty || isScanning)
            }
            .padding()

            if isScanning {
                ProgressView(value: progress)
                    .padding(.horizontal)
            }

            List {
                if let result {
                    ForEach(result.categories) { category in
                        Section("\(category.name) (\(ByteFormatter.format(category.totalBytes)))") {
                            ForEach(category.items) { item in
                                HStack {
                                    Toggle(isOn: Binding(
                                        get: { selectedItems.contains(item.id) },
                                        set: { on in
                                            if on { selectedItems.insert(item.id) }
                                            else { selectedItems.remove(item.id) }
                                        }
                                    )) {
                                        VStack(alignment: .leading) {
                                            Text(item.name)
                                                .lineLimit(1)
                                            Text(item.path)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                    Text(ByteFormatter.format(item.sizeBytes))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@MainActor
final class ToolScanViewModel: ObservableObject {
    @Published var result: ScanResult?
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var selectedItems: Set<String> = []
    @Published var message: String?

    let scanner: any ScanningService

    init(scanner: any ScanningService) {
        self.scanner = scanner
    }

    func scan() async {
        isScanning = true
        progress = 0
        defer { isScanning = false }
        do {
            let scanResult = try await scanner.scan { [weak self] value in
                Task { @MainActor in self?.progress = value }
            }
            result = scanResult
            selectedItems = Set(scanResult.allItems.map(\.id))
        } catch {
            message = error.localizedDescription
        }
    }

    func clean() async {
        guard let result else { return }
        let items = result.allItems.filter { selectedItems.contains($0.id) }
        isScanning = true
        defer { isScanning = false }
        do {
            let freed = try await scanner.clean(items: items)
            message = "Freed \(ByteFormatter.format(freed))"
            await scan()
        } catch {
            message = error.localizedDescription
        }
    }
}
