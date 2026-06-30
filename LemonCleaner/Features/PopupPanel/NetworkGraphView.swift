import SwiftUI

struct NetworkGraphView: View {
    let uploadHistory: [Double]
    let downloadHistory: [Double]

    var body: some View {
        GeometryReader { geo in
            let maxValue = max(
                uploadHistory.max() ?? 1,
                downloadHistory.max() ?? 1,
                1
            )
            ZStack {
                // Download (bottom, green)
                graphPath(
                    values: downloadHistory,
                    in: geo.size,
                    maxValue: maxValue,
                    mirrored: true
                )
                .fill(AppTheme.cleanGreen.opacity(0.25))

                // Upload (top, blue)
                graphPath(
                    values: uploadHistory,
                    in: geo.size,
                    maxValue: maxValue,
                    mirrored: false
                )
                .fill(AppTheme.linkBlue.opacity(0.25))

                // Center line
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
                }
                .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 0.5)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }

    private func graphPath(values: [Double], in size: CGSize, maxValue: Double, mirrored: Bool) -> Path {
        Path { path in
            guard !values.isEmpty else { return }
            let midY = size.height / 2
            let stepX = size.width / CGFloat(max(values.count - 1, 1))

            for (index, value) in values.enumerated() {
                let x = CGFloat(index) * stepX
                let normalized = CGFloat(value / maxValue)
                let amplitude = (size.height / 2 - 4) * normalized
                let y = mirrored ? midY + amplitude : midY - amplitude
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: midY))
                }
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: size.width, y: midY))
            path.closeSubpath()
        }
    }
}
