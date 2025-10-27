//
//  APILogger.swift
//  DirectorStudio
//
//  PURPOSE: Persistent API logging system that writes to files
//

import Foundation
import SwiftUI

/// Global API logger that writes to files and memory
public class APILogger: ObservableObject {
    static let shared = APILogger()
    
    @Published var logs: [LogEntry] = []
    private let logFileURL: URL
    private let maxMemoryLogs = 1000
    private let dateFormatter: DateFormatter
    
    struct LogEntry: Identifiable, Codable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let type: LogType
        let metadata: [String: String]?
        
        enum LogType: String, Codable {
            case info
            case request
            case response
            case error
            case success
            case debug
            
            var emoji: String {
                switch self {
                case .info: return "ℹ️"
                case .request: return "📤"
                case .response: return "📥"
                case .error: return "❌"
                case .success: return "✅"
                case .debug: return "🔍"
                }
            }
        }
    }
    
    init() {
        // Create log file in Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logFileURL = documentsPath.appendingPathComponent("api_debug_log.txt")
        
        // Setup date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Create initial log file
        createLogFileIfNeeded()
        
        // Log startup
        log("=== API Logger Started ===", type: .info)
        log("Log file: \(logFileURL.path)", type: .info)
    }
    
    private func createLogFileIfNeeded() {
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            let header = """
            DirectorStudio API Debug Log
            Created: \(Date())
            =====================================
            
            """
            try? header.write(to: logFileURL, atomically: true, encoding: .utf8)
        }
    }
    
    /// Log a message
    func log(_ message: String, type: LogEntry.LogType = .info, metadata: [String: String]? = nil) {
        let entry = LogEntry(timestamp: Date(), message: message, type: type, metadata: metadata)
        
        // Add to memory
        DispatchQueue.main.async {
            self.logs.append(entry)
            if self.logs.count > self.maxMemoryLogs {
                self.logs.removeFirst(self.logs.count - self.maxMemoryLogs)
            }
        }
        
        // Write to file
        writeToFile(entry)
        
        // Also print to console
        print("\(entry.type.emoji) \(message)")
    }
    
    /// Log with automatic type detection
    func logAPI(_ message: String) {
        let type: LogEntry.LogType
        if message.contains("REQUEST") || message.contains("📤") {
            type = .request
        } else if message.contains("RESPONSE") || message.contains("📥") {
            type = .response
        } else if message.contains("ERROR") || message.contains("❌") {
            type = .error
        } else if message.contains("SUCCESS") || message.contains("✅") {
            type = .success
        } else {
            type = .info
        }
        log(message, type: type)
    }
    
    private func writeToFile(_ entry: LogEntry) {
        let timestamp = dateFormatter.string(from: entry.timestamp)
        var logLine = "[\(timestamp)] \(entry.type.emoji) [\(entry.type.rawValue.uppercased())] \(entry.message)"
        
        if let metadata = entry.metadata {
            let metadataString = metadata.map { "  \($0.key): \($0.value)" }.joined(separator: "\n")
            logLine += "\n\(metadataString)"
        }
        
        logLine += "\n"
        
        if let data = logLine.data(using: .utf8) {
            if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()
            }
        }
    }
    
    /// Get the current log file path
    func getLogFilePath() -> String {
        return logFileURL.path
    }
    
    /// Read the entire log file
    func readLogFile() -> String {
        do {
            return try String(contentsOf: logFileURL, encoding: .utf8)
        } catch {
            return "Error reading log file: \(error)"
        }
    }
    
    /// Clear all logs
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
        
        // Recreate log file
        try? FileManager.default.removeItem(at: logFileURL)
        createLogFileIfNeeded()
    }
    
    /// Export logs as shareable text
    func exportLogs() -> String {
        var export = """
        DirectorStudio API Debug Log Export
        Generated: \(Date())
        =====================================
        
        """
        
        // Add memory logs
        for entry in logs {
            let timestamp = dateFormatter.string(from: entry.timestamp)
            export += "[\(timestamp)] \(entry.type.emoji) \(entry.message)\n"
            if let metadata = entry.metadata {
                for (key, value) in metadata {
                    export += "  \(key): \(value)\n"
                }
            }
        }
        
        return export
    }
    
    /// Get file URL for sharing
    func getShareableFileURL() -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("api_debug_log_export.txt")
        
        do {
            let logContent = readLogFile()
            try logContent.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            log("Failed to create shareable file: \(error)", type: .error)
            return nil
        }
    }
}

/// Debug view with export functionality
public struct APIDebugView: View {
    @ObservedObject private var logger = APILogger.shared
    @State private var showingShareSheet = false
    @State private var searchText = ""
    @State private var selectedType: APILogger.LogEntry.LogType?
    
    private var filteredLogs: [APILogger.LogEntry] {
        var logs = logger.logs
        
        // Filter by type
        if let type = selectedType {
            logs = logs.filter { $0.type == type }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
        
        return logs
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filters
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search logs...", text: $searchText)
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Type filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterChip(title: "All", isSelected: selectedType == nil) {
                                selectedType = nil
                            }
                            ForEach([APILogger.LogEntry.LogType.info, .request, .response, .error, .success], id: \.self) { type in
                                FilterChip(
                                    title: "\(type.emoji) \(type.rawValue.capitalized)",
                                    isSelected: selectedType == type
                                ) {
                                    selectedType = type
                                }
                            }
                        }
                    }
                }
                .padding()
                
                // Log info
                HStack {
                    Text("\(filteredLogs.count) logs")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    Text("Log file: \(logger.getLogFilePath())")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                
                // Log list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(filteredLogs) { log in
                                APILogRow(log: log)
                                    .id(log.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: logger.logs.count) { _ in
                        // Auto-scroll to bottom
                        if let lastLog = filteredLogs.last {
                            withAnimation {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            .navigationTitle("API Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        logger.clearLogs()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = logger.getShareableFileURL() {
                ShareSheet(items: [url])
            }
        }
    }
}

struct APILogRow: View {
    let log: APILogger.LogEntry
    @State private var expanded = false
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: log.timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Text(log.type.emoji)
                    .font(.caption)
                
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text(log.message)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(expanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                if log.message.count > 100 {
                    Button(action: { expanded.toggle() }) {
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            if let metadata = log.metadata {
                VStack(alignment: .leading) {
                    ForEach(Array(metadata.keys.sorted()), id: \.self) { key in
                        Text("  \(key): \(metadata[key] ?? "")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    APIDebugView()
}

