import SwiftUI

struct ProgressOverlay: View {
    let progress: Double
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(width: 200)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThickMaterial)
        )
    }
}
