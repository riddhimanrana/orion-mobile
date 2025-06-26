import SwiftUI
import Combine

struct TitleView: View {
    @State private var gradientStart = UnitPoint(x: -0.5, y: 0.5)
    @State private var gradientEnd = UnitPoint(x: 1.5, y: 0.5)

    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Base text for a subtle glow
            Text("Orion Live")
                .font(.custom("EditUndoBRK", size: 60))
                .foregroundColor(.white)
                .blur(radius: 15)
                .opacity(0.5)

            // Main text with animated gradient
            Text("Orion Live")
                .font(.custom("EditUndoBRK", size: 60))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [.cyan, .blue, .purple, .blue, .cyan]),
                        startPoint: gradientStart,
                        endPoint: gradientEnd
                    )
                )
                .shadow(color: .blue.opacity(0.8), radius: 20, x: 0, y: 0)
                .onReceive(timer) { _ in
                    withAnimation(.easeInOut(duration: 2)) {
                        gradientStart = UnitPoint(x: 1.5, y: 0.5)
                        gradientEnd = UnitPoint(x: 2.5, y: 0.5)
                    }
                    // Reset the gradient to create a continuous loop
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        gradientStart = UnitPoint(x: -0.5, y: 0.5)
                        gradientEnd = UnitPoint(x: 0.5, y: 0.5)
                    }
                }
        }
    }
}

struct TitleView_Previews: PreviewProvider {
    static var previews: some View {
        TitleView()
            .preferredColorScheme(.dark)
    }
}
