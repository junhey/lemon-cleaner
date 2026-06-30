import SwiftUI

struct HexagonLogo: View {
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                HexagonShape()
                    .stroke(Color.gray.opacity(0.08), lineWidth: 1)
                    .frame(width: size * (0.6 + CGFloat(index) * 0.2))
                    .rotationEffect(.degrees(Double(index) * 15))
            }
            HexagonShape()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.85, blue: 0.3), AppTheme.lemonAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.55, height: size * 0.55)
                .shadow(color: AppTheme.lemonAccent.opacity(0.3), radius: 12)
            HexagonShape()
                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                .frame(width: size * 0.35, height: size * 0.35)
        }
        .frame(width: size, height: size)
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
