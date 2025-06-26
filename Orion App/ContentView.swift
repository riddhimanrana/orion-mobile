import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var wsManager = WebSocketManager()
    
    @State private var latestAnalysis: SceneAnalysis?
    @State private var analysisTimestamp: TimeInterval = 0
    @State private var showErrorAlert = false
    @State private var alertMessage = ""

    var body: some View {
        TabView {
            // Tab 1: Camera Feed
            CameraTabView(
                wsManager: wsManager,
                latestAnalysis: $latestAnalysis,
                analysisTimestamp: $analysisTimestamp
            )
            .environmentObject(cameraManager)
            .environmentObject(appState)
            .tabItem {
                Image(systemName: "camera.fill")
                Text("Camera")
            }
            
            // Tab 2: Scene Analysis
            SceneAnalysisTabView(
                latestAnalysis: latestAnalysis,
                analysisTimestamp: analysisTimestamp
            )
            .environmentObject(wsManager)
            .environmentObject(appState)
            .tabItem {
                Image(systemName: "brain.head.profile")
                Text("Scene Analysis")
            }
            
            // Tab 3: Debug
            DebugTabView()
            .environmentObject(wsManager)
            .environmentObject(appState)
            .environmentObject(cameraManager)
            .tabItem {
                Image(systemName: "ladybug.fill")
                Text("Debug")
            }
        }
        .onAppear {
            setupManagers()
            cameraManager.startStreaming()
        }
        .onReceive(cameraManager.$error) { cameraError in
            if let camError = cameraError, !camError.isEmpty {
                self.alertMessage = "Camera Error: \(camError)"
                self.showErrorAlert = true
                Logger.shared.log("CameraManager published error: \(camError)", level: .error, category: .camera)
            }
        }
        .alert("Application Alert", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func setupManagers() {
        wsManager.onError = { wsError in
            DispatchQueue.main.async {
                if !self.showErrorAlert || !self.alertMessage.starts(with: "Camera Error:") {
                    self.alertMessage = "WebSocket Error: \(wsError.localizedDescription)"
                    self.showErrorAlert = true
                }
                Logger.shared.log("WebSocketManager reported error: \(wsError.localizedDescription)", level: .error, category: .network)
            }
        }
        
        wsManager.onAnalysis = { analysis in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: UIConfig.standardAnimationDuration)) {
                    self.latestAnalysis = analysis
                    self.analysisTimestamp = Date().timeIntervalSince1970
                }
            }
        }
        
        cameraManager.setDetectionCallback { imageData, detections in
            let frameData = DetectionFrame(
                frameId: UUID().uuidString,
                timestamp: Date().timeIntervalSince1970,
                imageData: imageData?.base64EncodedString(),
                detections: detections
            )
            
            if wsManager.status == .connected {
                wsManager.sendFrame(frameData)
            }
        }
        
        wsManager.connect()
        
        #if DEBUG
        WebSocketManager.enableLogging = DebugConfig.enableNetworkLogs
        #endif
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppStateManager()
        let cameraManager = CameraManager()
        
        appState.performanceMetrics = PerformanceMetrics(fps: 29.5, memoryUsage: 120.3, batteryLevel: 0.75, temperature: 0)

        return ContentView()
            .environmentObject(appState)
            .environmentObject(cameraManager)
    }
}
