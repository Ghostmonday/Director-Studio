//
//  SegmentationDebugView.swift
//  DirectorStudio
//
//  Real-time segmentation log viewer for debugging
//

import SwiftUI
import Combine

struct SegmentationDebugView: View {
    @StateObject private var logManager = SegmentationLogManager.shared
    @State private var isVisible = false
    @State private var autoScroll = true
    @State private var searchText = ""
    @State private var filterLevel: LogLevel = .all
    @Environment(\.dismiss) private var dismiss
    
    enum LogLevel: String, CaseIterable {
        case all = "All"
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
        case success = "Success"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .info: return "info.circle"
            case .warning: return "exclamationmark.triangle"
            case .error: return "xmark.circle"
            case .success: return "checkmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .primary
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .success: return .green
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar
                
                // Log Content
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(filteredLogs) { log in
                                LogEntryView(log: log)
                                    .id(log.id)
                            }
                            
                            // Auto-scroll anchor
                            Color.clear
                                .frame(height: 1)
                                .id("bottom")
                                .onChange(of: logManager.logs.count) { _ in
                                    if autoScroll {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            proxy.scrollTo("bottom", anchor: .bottom)
                                        }
                                    }
                                }
                        }
                        .padding()
                    }
                    .background(Color.black.opacity(0.95))
                    .onAppear {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                
                // Controls
                controlBar
            }
            .navigationTitle("🎬 Segmentation Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var filterBar: some View {
        HStack {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(Color.white.opacity(0.1))
            .cornerRadius(8)
            
            // Filter Level
            Picker("Filter", selection: $filterLevel) {
                ForEach(LogLevel.allCases, id: \.self) { level in
                    Label(level.rawValue, systemImage: level.icon)
                        .tag(level)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    private var controlBar: some View {
        HStack {
            // Log Stats
            HStack(spacing: 16) {
                ForEach(LogLevel.allCases.filter { $0 != .all }, id: \.self) { level in
                    HStack(spacing: 4) {
                        Image(systemName: level.icon)
                            .foregroundColor(level.color)
                            .font(.caption)
                        Text("\(logCount(for: level))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Auto-scroll toggle
            Toggle(isOn: $autoScroll) {
                Label("Auto-scroll", systemImage: "arrow.down.to.line")
                    .font(.caption)
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            
            // Clear logs
            Button(action: { logManager.clear() }) {
                Label("Clear", systemImage: "trash")
                    .font(.caption)
            }
            .foregroundColor(.red)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    private var filteredLogs: [SegmentationLog] {
        logManager.logs.filter { log in
            let matchesSearch = searchText.isEmpty || 
                log.message.localizedCaseInsensitiveContains(searchText)
            let matchesLevel = filterLevel == .all || log.level == filterLevel
            return matchesSearch && matchesLevel
        }
    }
    
    private func logCount(for level: LogLevel) -> Int {
        logManager.logs.filter { $0.level == level }.count
    }
}

struct LogEntryView: View {
    let log: SegmentationLog
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                // Level Icon
                Image(systemName: log.level.icon)
                    .foregroundColor(log.level.color)
                    .font(.caption)
                    .frame(width: 20)
                
                // Timestamp
                Text(log.timestamp, formatter: timeFormatter)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .frame(width: 60, alignment: .leading)
                
                // Message
                Text(log.message)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(textColor)
                    .lineLimit(isExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Expand button for long messages
                if log.message.count > 100 {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Details (if any)
            if let details = log.details, isExpanded {
                Text(details)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.gray)
                    .padding(.leading, 90)
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
        .background(backgroundColor)
        .onTapGesture {
            if log.message.count > 100 {
                isExpanded.toggle()
            }
        }
    }
    
    private var textColor: Color {
        switch log.level {
        case .error: return .red
        case .warning: return .orange
        case .success: return .green
        default: return .white
        }
    }
    
    private var backgroundColor: Color {
        switch log.level {
        case .error: return Color.red.opacity(0.1)
        case .warning: return Color.orange.opacity(0.1)
        case .success: return Color.green.opacity(0.1)
        default: return Color.clear
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

// MARK: - Log Model

struct SegmentationLog: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let level: SegmentationDebugView.LogLevel
    let message: String
    let details: String?
    
    init(level: SegmentationDebugView.LogLevel = .info, message: String, details: String? = nil) {
        self.level = level
        self.message = message
        self.details = details
    }
}

// MARK: - Log Manager

class SegmentationLogManager: ObservableObject {
    static let shared = SegmentationLogManager()
    
    @Published var logs: [SegmentationLog] = []
    private let maxLogs = 1000
    private var logFileMonitor: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "com.directorstudio.logmanager")
    
    private init() {
        startMonitoringLogFile()
    }
    
    func log(_ message: String, level: SegmentationDebugView.LogLevel = .info, details: String? = nil) {
        DispatchQueue.main.async {
            let log = SegmentationLog(level: level, message: message, details: details)
            self.logs.append(log)
            
            // Limit log count
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }
        }
    }
    
    func clear() {
        logs.removeAll()
    }
    
    private func startMonitoringLogFile() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let logFileURL = documentsPath.appendingPathComponent("segmentation_debug.txt")
        
        // Read existing content
        if let existingContent = try? String(contentsOf: logFileURL) {
            parseLogContent(existingContent)
        }
        
        // Monitor for changes
        let fileDescriptor = open(logFileURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }
        
        logFileMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend],
            queue: queue
        )
        
        logFileMonitor?.setEventHandler { [weak self] in
            if let content = try? String(contentsOf: logFileURL),
               let lastLine = content.components(separatedBy: .newlines).last(where: { !$0.isEmpty }) {
                self?.parseLogLine(lastLine)
            }
        }
        
        logFileMonitor?.setCancelHandler {
            close(fileDescriptor)
        }
        
        logFileMonitor?.resume()
    }
    
    private func parseLogContent(_ content: String) {
        let lines = content.components(separatedBy: .newlines)
        for line in lines where !line.isEmpty {
            parseLogLine(line)
        }
    }
    
    private func parseLogLine(_ line: String) {
        // Determine log level based on content
        let level: SegmentationDebugView.LogLevel
        if line.contains("❌") || line.contains("FAILED") || line.contains("ERROR") {
            level = .error
        } else if line.contains("⚠️") || line.contains("WARNING") {
            level = .warning
        } else if line.contains("✅") || line.contains("SUCCESS") || line.contains("Complete") {
            level = .success
        } else {
            level = .info
        }
        
        // Extract message (remove timestamp if present)
        var message = line
        if line.contains("] ") {
            message = String(line.split(separator: "]", maxSplits: 1).last ?? "")
                .trimmingCharacters(in: .whitespaces)
        }
        
        log(message, level: level)
    }
    
    deinit {
        logFileMonitor?.cancel()
    }
}

// MARK: - Debug Button

struct SegmentationDebugButton: View {
    @State private var showDebugView = false
    @State private var hasNewLogs = false
    @ObservedObject private var logManager = SegmentationLogManager.shared
    
    var body: some View {
        Button(action: { showDebugView = true }) {
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.8))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                // New log indicator
                if hasNewLogs {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 20, y: -20)
                }
            }
        }
        .shadow(radius: 5)
        .sheet(isPresented: $showDebugView) {
            SegmentationDebugView()
                .onAppear { hasNewLogs = false }
        }
        .onChange(of: logManager.logs.count) { _ in
            if !showDebugView {
                hasNewLogs = true
            }
        }
    }
}

// MARK: - Integration Helper

extension SegmentingModule {
    /// Wrapper to add logging to the module
    func segmentWithLogging(
        script: String,
        mode: SegmentationMode,
        constraints: SegmentationConstraints = .default,
        llmConfig: LLMConfiguration? = nil
    ) async throws -> SegmentationResult {
        let logger = SegmentationLogManager.shared
        
        logger.log("🎬 Starting segmentation", level: .info)
        logger.log("Mode: \(mode.displayName)", level: .info)
        logger.log("Script length: \(script.count) characters", level: .info)
        
        do {
            let result = try await segment(
                script: script,
                mode: mode,
                constraints: constraints,
                llmConfig: llmConfig
            )
            
            logger.log("✅ Segmentation complete", level: .success)
            logger.log("Generated \(result.segments.count) segments", level: .success)
            
            for (index, segment) in result.segments.enumerated() {
                logger.log("Segment \(index + 1): \(segment.text.prefix(50))...", level: .info)
            }
            
            return result
        } catch {
            logger.log("❌ Segmentation failed: \(error.localizedDescription)", level: .error)
            throw error
        }
    }
}
