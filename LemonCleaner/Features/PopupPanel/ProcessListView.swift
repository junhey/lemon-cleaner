import SwiftUI

struct ProcessListView: View {
    let apps: [AppMemoryUsage]
    let memoryPercent: Double

    var body: some View {
        VStack(spacing: 0) {
            if apps.isEmpty {
                HStack {
                    Spacer()
                    Text("No apps using memory")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 12)
            } else {
                ForEach(apps) { app in
                    HStack(spacing: 8) {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 22, height: 22)
                        } else {
                            Image(systemName: "app.fill")
                                .frame(width: 22, height: 22)
                                .foregroundStyle(.secondary)
                        }
                        Text(app.name)
                            .font(.system(size: 12))
                            .lineLimit(1)
                        Spacer()
                        Text(ByteFormatter.format(app.memoryBytes))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, AppTheme.panelHorizontalPadding)
                    .padding(.vertical, 5)
                }
            }
        }
    }
}
