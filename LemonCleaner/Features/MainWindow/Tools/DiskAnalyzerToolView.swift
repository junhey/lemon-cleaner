import SwiftUI

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
