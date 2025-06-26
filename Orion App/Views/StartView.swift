import SwiftUI
import Combine

struct StartView: View {
    @Environment(\.colorScheme) var colorScheme
    @Binding var isCameraActive: Bool
    var onStart: () -> Void

    @State private var isLoading = false
    @State private var pulsating = false
    @State private var nodes: [Node] = []
    @State private var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    struct Node: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var size: CGFloat
        var speed: Double // Animation duration
        var opacity: Double
        var stretch: CGFloat = 1.0
        var angle: Double = 0.0
    }

    var body: some View {
        ZStack {
            // Background
            (colorScheme == .dark ? Color.black : Color.white).edgesIgnoringSafeArea(.all)

            // Animated particles
            ForEach(nodes) { node in
                Capsule()
                    .fill(Color.white.opacity(node.opacity))
                    .frame(width: node.size * node.stretch, height: node.size)
                    .rotationEffect(.degrees(node.angle))
                    .position(node.position)
            }
            .onAppear(perform: setupNodes)
            .onReceive(timer) { _ in
                guard !isLoading else {
                    timer.upstream.connect().cancel()
                    return
                }
                moveNodes()
            }

            VStack {
                Spacer()

                // Title
                Text("Orion Live")
                    .font(.system(size: 60, weight: .heavy))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .shadow(color: .cyan, radius: 20, x: 0, y: 0)
                    .scaleEffect(pulsating ? 1.05 : 1.0)
                    .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulsating)

                Spacer()

                // Start Button
                ZStack {
                    // Pulsating Glows
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(lineWidth: CGFloat(i * 5 + 5))
                            .fill(
                                AngularGradient(gradient: Gradient(colors: [.cyan, .blue, .purple, .cyan]), center: .center, startAngle: .degrees(0), endAngle: .degrees(360))
                            )
                            .frame(width: 150 + CGFloat(i * 50), height: 150 + CGFloat(i * 50))
                            .opacity(pulsating ? 0.2 : 0.5)
                            .scaleEffect(pulsating ? 1.1 : 1.0)
                            .animation(Animation.easeInOut(duration: 2.5 + Double(i)).repeatForever(autoreverses: true), value: pulsating)
                    }

                    // Button
                    Button(action: {
                        let haptic = UIImpactFeedbackGenerator(style: .heavy)
                        haptic.impactOccurred()
                        startLoading()
                    }) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(45)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
                            )
                            .overlay(
                                Circle()
                                    .stroke(LinearGradient(gradient: Gradient(colors: [colorScheme == .dark ? .white : .black, .cyan.opacity(0.5)]), startPoint: .top, endPoint: .bottom), lineWidth: 3)
                            )
                    }
                }
                .onAppear {
                    self.pulsating = true
                }
                
                Spacer()
                Spacer()
            }
            .blur(radius: isLoading ? 30 : 0)
            .scaleEffect(isLoading ? 0.5 : 1.0)
            .opacity(isLoading ? 0 : 1)
            .onAppear(perform: setupNodes)
            .animation(.easeInOut(duration: 1.2), value: isLoading)
        }
    }

    private func setupNodes() {
        nodes = (0..<150).map { _ in
            let size = CGFloat.random(in: 1...3)
            let speed = Double.random(in: 0.6...1.0) // Animation duration
            return Node(
                position: CGPoint(x: .random(in: 0...UIScreen.main.bounds.width), y: .random(in: 0...UIScreen.main.bounds.height)),
                velocity: CGVector(dx: .random(in: -0.2...0.2), dy: .random(in: -0.2...0.2)),
                size: size,
                speed: speed,
                opacity: .random(in: 0.2...0.8)
            )
        }
    }

    private func moveNodes() {
        for i in nodes.indices {
            nodes[i].position.x += nodes[i].velocity.dx
            nodes[i].position.y += nodes[i].velocity.dy

            if nodes[i].position.x < 0 || nodes[i].position.x > UIScreen.main.bounds.width {
                nodes[i].velocity.dx *= -1
            }
            if nodes[i].position.y < 0 || nodes[i].position.y > UIScreen.main.bounds.height {
                nodes[i].velocity.dy *= -1
            }
        }
    }
    
    private func triggerHyperspeed() {
        let center = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let maxDimension = max(screenWidth, screenHeight)

        // 1. Prepare nodes for animation by assigning them a random outward angle
        for i in nodes.indices {
            let angle = Double.random(in: 0..<360)
            nodes[i].angle = angle
            nodes[i].position = center // Start all nodes from the center
            nodes[i].stretch = 1.0
            nodes[i].opacity = 0.8 // Make them visible for the burst
        }

        // 2. Trigger the animation
        for i in nodes.indices {
            let node = nodes[i]
            let angleRad = node.angle * .pi / 180

            // Streaks will be long enough to shoot off-screen
            let streakLength: CGFloat = maxDimension * 1.5 // Ensure it goes far off-screen

            // The final position is the center of the stretched capsule.
            // If the base is at 'center', then the center of the capsule is 'streakLength / 2' away from 'center'.
            let finalPosition = CGPoint(
                x: center.x + CGFloat(cos(Double(angleRad))) * (streakLength / 2),
                y: center.y + CGFloat(sin(Double(angleRad))) * (streakLength / 2)
            )

            withAnimation(.easeOut(duration: node.speed).delay(Double.random(in: 0...0.15))) {
                nodes[i].stretch = streakLength
                nodes[i].position = finalPosition
                nodes[i].opacity = 0
            }
        }

        // 3. Transition to camera view after the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                isCameraActive = true
            }
        }
    }

    private func startLoading() {
        isLoading = true
        triggerHyperspeed()
        onStart()
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView(isCameraActive: .constant(false), onStart: {})
    }
}

