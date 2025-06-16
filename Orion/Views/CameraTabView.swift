//
//  CameraTabView.swift
//  Orion
//
//  Created by Riddhiman Rana on 6/16/25.
//


//
//  CameraTabView.swift
//  Orion
//
//  Created by Roo on 6/16/25.
//  Camera tab with YOLOv11n object detection overlay
//

import SwiftUI
import Combine

struct CameraTabView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @EnvironmentObject var appState: AppStateManager
    @ObservedObject var wsManager: WebSocketManager
    
    @Binding var latestAnalysis: SceneAnalysis?
    @Binding var analysisTimestamp: TimeInterval
    @State private var showingSettingsSheet = false
    
    private var safeAreaTopInset: CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return windowScene?.windows.first?.safeAreaInsets.top ?? 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera view with detection overlays
                CameraView()
                    .environmentObject(cameraManager)
                    .ignoresSafeArea()
                
                VStack {
                    // Top overlay with status and controls
                    HStack {
                        connectionStatusView
                        Spacer()
                        performanceMetricsView
                        settingsButton
                    }
                    .padding(.top, safeAreaTopInset)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Bottom overlay with detection stats
                    if !cameraManager.lastDetections.isEmpty {
                        detectionStatsView
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
                .environmentObject(wsManager)
                .environmentObject(appState)
        }
    }
    
    // MARK: - Connection Status View
    private var connectionStatusView: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(webSocketStatusColor)
                .frame(width: 10, height: 10)
                .animation(.easeInOut, value: wsManager.status)
            
            Text(webSocketStatusText)
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    private var webSocketStatusColor: Color {
        switch wsManager.status {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected:
            return .red
        }
    }
    
    private var webSocketStatusText: String {
        switch wsManager.status {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnected:
            return "Disconnected"
        }
    }
    
    // MARK: - Performance Metrics View
    private var performanceMetricsView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("FPS: \(String(format: "%.1f", appState.performanceMetrics.fps))")
                .font(.caption.weight(.medium))
            Text("Mem: \(String(format: "%.1f", appState.performanceMetrics.memoryUsage))MB")
                .font(.caption.weight(.medium))
        }
        .foregroundColor(.white)
        .padding(EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10))
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
    
    // MARK: - Settings Button
    private var settingsButton: some View {
        Button {
            showingSettingsSheet = true
        } label: {
            Image(systemName: "gearshape.fill")
                .imageScale(.large)
                .foregroundColor(.white)
                .padding(10)
                .background(Circle().fill(.ultraThinMaterial))
        }
        .accessibilityLabel("Settings")
    }
    
    // MARK: - Detection Stats View
    private var detectionStatsView: some View {
        HStack(spacing: 16) {
            // Detection count
            VStack(spacing: 2) {
                Text("\(cameraManager.lastDetections.count)")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text("Objects")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Divider()
                .background(.white.opacity(0.3))
                .frame(height: 30)
            
            // Average confidence
            VStack(spacing: 2) {
                Text("\(averageConfidence, specifier: "%.0f")%")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text("Confidence")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Divider()
                .background(.white.opacity(0.3))
                .frame(height: 30)
            
            // Processing status
            VStack(spacing: 2) {
                Image(systemName: processingIndicator)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.white)
                Text("Processing")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .animation(.easeInOut, value: cameraManager.lastDetections.count)
    }
    
    private var averageConfidence: Double {
        guard !cameraManager.lastDetections.isEmpty else { return 0 }
        let total = cameraManager.lastDetections.reduce(0) { $0 + $1.confidence }
        return Double(total) / Double(cameraManager.lastDetections.count) * 100
    }
    
    private var processingIndicator: String {
        if cameraManager.lastDetections.isEmpty {
            return "magnifyingglass"
        } else {
            return "checkmark.circle.fill"
        }
    }
}

// MARK: - Preview
struct CameraTabView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppStateManager()
        let cameraManager = CameraManager()
        let wsManager = WebSocketManager()
        
        appState.performanceMetrics = PerformanceMetrics(
            fps: 29.5,
            memoryUsage: 120.3,
            batteryLevel: 0.75,
            temperature: 0
        )
        
        return CameraTabView(
            wsManager: wsManager,
            latestAnalysis: .constant(nil),
            analysisTimestamp: .constant(0)
        )
        .environmentObject(appState)
        .environmentObject(cameraManager)
    }
}