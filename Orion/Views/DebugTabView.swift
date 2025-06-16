//
//  DebugTabView.swift
//  Orion
//
//  Created by Riddhiman Rana on 6/16/25.
//


//
//  DebugTabView.swift
//  Orion
//
//  Created by Roo on 6/16/25.
//  Debug tab with server data, WebSocket status, and debug information
//

import SwiftUI
import Combine

struct DebugTabView: View {
    @EnvironmentObject var wsManager: WebSocketManager
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var cameraManager: CameraManager
    
    @State private var networkLogs: [NetworkLogEntry] = []
    @State private var detectionLogs: [DetectionLogEntry] = []
    @State private var showingRawJSONViewer = false
    @State private var keyframeInterval: Double = 1.0
    @State private var selectedLogCategory: LogCategory = .all
    @State private var showingSettingsSheet = false
    @State private var autoScrollEnabled = true
    
    private let logUpdateTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // System Status Section
                    systemStatusSection
                    
                    // WebSocket Connection Section
                    webSocketStatusSection
                    
                    // Processing Metrics Section
                    processingMetricsSection
                    
                    // Keyframe Configuration Section
                    keyframeConfigSection
                    
                    // Network Activity Section
                    networkActivitySection
                    
                    // Detection Logs Section
                    detectionLogsSection
                    
                    // Raw Data Viewer Section
                    rawDataSection
                }
                .padding()
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        clearAllLogs()
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettingsSheet = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingRawJSONViewer) {
            RawJSONViewer()
                .environmentObject(wsManager)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            DebugSettingsView()
                .environmentObject(wsManager)
        }
        .onReceive(logUpdateTimer) { _ in
            updateLogs()
        }
    }
    
    // MARK: - System Status Section
    private var systemStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Status")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatusCard(
                    title: "FPS",
                    value: String(format: "%.1f", appState.performanceMetrics.fps),
                    icon: "speedometer",
                    color: fpsColor
                )
                
                StatusCard(
                    title: "Memory",
                    value: String(format: "%.1f MB", appState.performanceMetrics.memoryUsage),
                    icon: "memorychip",
                    color: memoryColor
                )
                
                StatusCard(
                    title: "Battery",
                    value: String(format: "%.0f%%", appState.performanceMetrics.batteryLevel * 100),
                    icon: "battery.100",
                    color: batteryColor
                )
                
                StatusCard(
                    title: "Detections",
                    value: "\(cameraManager.lastDetections.count)",
                    icon: "viewfinder",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - WebSocket Status Section
    private var webSocketStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("WebSocket Connection")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ConnectionStatusRow(
                    label: "Status",
                    value: connectionStatusText,
                    color: connectionStatusColor
                )
                
                ConnectionStatusRow(
                    label: "Server",
                    value: "\(ServerConfig.host):\(ServerConfig.port)",
                    color: .secondary
                )
                
                ConnectionStatusRow(
                    label: "Reconnect Delay",
                    value: "\(ServerConfig.reconnectDelay)s",
                    color: .secondary
                )
                
                ConnectionStatusRow(
                    label: "Ping Interval",
                    value: "\(ServerConfig.pingInterval)s",
                    color: .secondary
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Processing Metrics Section
    private var processingMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Processing Metrics")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                MetricRow(
                    label: "Camera FPS",
                    value: String(format: "%.1f", appState.performanceMetrics.fps),
                    target: "30.0"
                )
                
                MetricRow(
                    label: "Processing Time",
                    value: String(format: "%.1f ms", appState.performanceMetrics.processingTime * 1000),
                    target: "< 33.3"
                )
                
                MetricRow(
                    label: "Frame Queue",
                    value: "0", // This would need to be tracked in CameraManager
                    target: "< 5"
                )
                
                MetricRow(
                    label: "Confidence Threshold",
                    value: String(format: "%.2f", CameraConfig.confidenceThreshold),
                    target: "0.50"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Keyframe Configuration Section
    private var keyframeConfigSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyframe Configuration")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Capture Interval")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(keyframeInterval, specifier: "%.1f")s")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $keyframeInterval, in: 0.1...5.0, step: 0.1)
                    .accentColor(.blue)
                
                HStack {
                    Button("Reset to Default") {
                        keyframeInterval = 1.0
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Spacer()
                    
                    Button("Apply Changes") {
                        // Apply keyframe interval changes
                        updateKeyframeInterval()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Network Activity Section
    private var networkActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Network Activity")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Log Category", selection: $selectedLogCategory) {
                    ForEach(LogCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
            
            if networkLogs.isEmpty {
                Text("No network activity recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(filteredNetworkLogs.suffix(10), id: \.id) { log in
                        NetworkLogRow(log: log)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Detection Logs Section
    private var detectionLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detection Logs")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            if detectionLogs.isEmpty {
                Text("No detection logs recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 4) {
                    ForEach(detectionLogs.suffix(10), id: \.id) { log in
                        DetectionLogRow(log: log)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Raw Data Section
    private var rawDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Raw Data Viewer")
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Button("View JSON Data") {
                    showingRawJSONViewer = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                
                Button("Export Logs") {
                    exportLogs()
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                
                Spacer()
                
                Toggle("Auto-scroll", isOn: $autoScrollEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Helper Properties
    
    private var filteredNetworkLogs: [NetworkLogEntry] {
        switch selectedLogCategory {
        case .all:
            return networkLogs
        case .sent:
            return networkLogs.filter { $0.type == .sent }
        case .received:
            return networkLogs.filter { $0.type == .received }
        case .error:
            return networkLogs.filter { $0.type == .error }
        }
    }
    
    private var connectionStatusText: String {
        switch wsManager.status {
        case .connected: return "Connected"
        case .connecting: return "Connecting..."
        case .disconnected: return "Disconnected"
        }
    }
    
    private var connectionStatusColor: Color {
        switch wsManager.status {
        case .connected: return .green
        case .connecting: return .yellow
        case .disconnected: return .red
        }
    }
    
    private var fpsColor: Color {
        let fps = appState.performanceMetrics.fps
        if fps >= 25 { return .green }
        else if fps >= 15 { return .yellow }
        else { return .red }
    }
    
    private var memoryColor: Color {
        let memory = appState.performanceMetrics.memoryUsage
        if memory < 200 { return .green }
        else if memory < 400 { return .yellow }
        else { return .red }
    }
    
    private var batteryColor: Color {
        let battery = appState.performanceMetrics.batteryLevel
        if battery > 0.5 { return .green }
        else if battery > 0.2 { return .yellow }
        else { return .red }
    }
    
    // MARK: - Helper Methods
    
    private func updateLogs() {
        // Simulate network log entries (in real implementation, these would come from WebSocketManager)
        if wsManager.status == .connected && Int.random(in: 0...10) > 7 {
            let logEntry = NetworkLogEntry(
                type: .sent,
                message: "Frame data sent - \(cameraManager.lastDetections.count) detections",
                timestamp: Date()
            )
            networkLogs.append(logEntry)
        }
        
        // Simulate detection log entries
        if !cameraManager.lastDetections.isEmpty && Int.random(in: 0...10) > 8 {
            let detectionEntry = DetectionLogEntry(
                detectionsCount: cameraManager.lastDetections.count,
                averageConfidence: cameraManager.lastDetections.map { $0.confidence }.reduce(0, +) / Float(cameraManager.lastDetections.count),
                processingTime: Double.random(in: 20...40),
                timestamp: Date()
            )
            detectionLogs.append(detectionEntry)
        }
        
        // Keep logs manageable
        if networkLogs.count > 100 {
            networkLogs.removeFirst(10)
        }
        if detectionLogs.count > 100 {
            detectionLogs.removeFirst(10)
        }
    }
    
    private func clearAllLogs() {
        networkLogs.removeAll()
        detectionLogs.removeAll()
    }
    
    private func updateKeyframeInterval() {
        // This would update the actual keyframe capture interval
        Logger.shared.log("Keyframe interval updated to \(keyframeInterval)s", category: .general)
    }
    
    private func exportLogs() {
        // This would export logs to a file
        Logger.shared.log("Exporting debug logs", category: .general)
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline.weight(.semibold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct ConnectionStatusRow: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(color)
        }
        .padding(.vertical, 2)
    }
}

struct MetricRow: View {
    let label: String
    let value: String
    let target: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("Target: \(target)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct NetworkLogRow: View {
    let log: NetworkLogEntry
    
    private var typeColor: Color {
        switch log.type {
        case .sent: return .blue
        case .received: return .green
        case .error: return .red
        }
    }
    
    private var typeIcon: String {
        switch log.type {
        case .sent: return "arrow.up.circle.fill"
        case .received: return "arrow.down.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: typeIcon)
                .foregroundColor(typeColor)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.message)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(log.formattedTimestamp)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

struct DetectionLogRow: View {
    let log: DetectionLogEntry
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "viewfinder")
                .foregroundColor(.blue)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(log.detectionsCount) objects detected")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                Text("Avg confidence: \(log.averageConfidence, specifier: "%.2f") • \(log.processingTime, specifier: "%.1f")ms")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(log.formattedTimestamp)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Data Models

enum LogCategory: String, CaseIterable {
    case all = "All"
    case sent = "Sent"
    case received = "Received"
    case error = "Error"
}

enum NetworkLogType {
    case sent
    case received
    case error
}

struct NetworkLogEntry: Identifiable {
    let id = UUID()
    let type: NetworkLogType
    let message: String
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}

struct DetectionLogEntry: Identifiable {
    let id = UUID()
    let detectionsCount: Int
    let averageConfidence: Float
    let processingTime: Double
    let timestamp: Date
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
}

// MARK: - Raw JSON Viewer

struct RawJSONViewer: View {
    @EnvironmentObject var wsManager: WebSocketManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Raw JSON data viewer will be implemented here")
                        .foregroundColor(.secondary)
                        .padding()
                    
                    // Placeholder for raw JSON content
                    Text("""
                    {
                        "frame_id": "12345",
                        "timestamp": \(Date().timeIntervalSince1970),
                        "detections": [],
                        "analysis": {
                            "scene_description": "...",
                            "confidence": 0.92
                        }
                    }
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .padding()
                }
            }
            .navigationTitle("Raw JSON Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Debug Settings View

struct DebugSettingsView: View {
    @EnvironmentObject var wsManager: WebSocketManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Logging") {
                    Toggle("Network Logs", isOn: .constant(DebugConfig.enableNetworkLogs))
                    Toggle("Processing Logs", isOn: .constant(DebugConfig.enableProcessingLogs))
                    Toggle("Performance Metrics", isOn: .constant(DebugConfig.enablePerformanceMetrics))
                }
                
                Section("Development") {
                    Toggle("Show Debug Overlay", isOn: .constant(DebugConfig.showDebugOverlay))
                    Toggle("Simulate Detections", isOn: .constant(DebugConfig.simulateDetections))
                }
            }
            .navigationTitle("Debug Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct DebugTabView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppStateManager()
        let cameraManager = CameraManager()
        let wsManager = WebSocketManager()
        
        appState.performanceMetrics = PerformanceMetrics(
            fps: 29.5,
            memoryUsage: 180.3,
            batteryLevel: 0.75,
            temperature: 0
        )
        
        return DebugTabView()
            .environmentObject(appState)
            .environmentObject(cameraManager)
            .environmentObject(wsManager)
    }
}