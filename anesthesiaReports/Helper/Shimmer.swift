import SwiftUI

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.white.opacity(0.6),
                                        Color.clear
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(25))
                            .offset(x: phase * width * 1.8)
                    }
                    .clipped()
                    .blendMode(.plusLighter)
                }
                .onAppear {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    @ViewBuilder func shimmering(active: Bool = true) -> some View {
        modifier(ShimmerModifier(isActive: active))
    }
}

#Preview {
    VStack(spacing: 16) {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .frame(height: 80)
            .shimmering()
        Text("Shimmering placeholder")
            .font(.headline)
            .shimmering(active: true)
    }
    .padding()
}
