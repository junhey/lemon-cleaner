import SwiftUI

struct ProcessListView: View {
    let apps: [AppMemoryUsage]
    let memoryPercent: Double

    var body: some View {
        VStack(spacing: 0) {
            ForEach(apps) { app in
                HStack(spacing: 10) {
                    if let icon = app.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "app.fill")
                            .frame(width: 24, height: 24)
                            .foregroundStyle(.secondary)
                    }
                    Text(app.name)
                        .font(.system(size: 13))
                        .lineLimit(1)
                    Spacer()
                    Text(ByteFormatter.format(app.memoryBytes))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
        }
    }
}
