//
//  DebugConsoleView.swift
//  DirectorStudio
//
//  PURPOSE: Debug console for viewing API logs in real-time
//

import SwiftUI

/// Global debug logger
public class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    
    @Published var logs: [LogEntry] = []
    private let maxLogs = 500
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let type: LogType
        
        enum LogType {
            case info
            case request
            case response
            case error
            case success
            
            var color: Color {
                switch self {
                case .info: return .blue
                case .request: return .orange
                case .response: return .green
                case .error: return .red
                case .success: return .green
                }
            }
            
            var icon: String {
                switch self {
                case .info: return "info.circle"
                case .request: return "arrow.up.circle"
                case .response: return "arrow.down.circle"
                case .error: return "exclamationmark.triangle"
                case .success: return "checkmark.circle"
                }
            }
        }
    }
    
    func log(_ message: String, type: LogEntry.LogType = .info) {
        DispatchQueue.main.async {
            let entry = LogEntry(timestamp: Date(), message: message, type: type)
            self.logs.append(entry)
            
            // Keep only the last maxLogs entries
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }
            
            // Also print to console
            let typeEmoji = switch type {
            case .info: "ℹ️"
            case .request: "📤"
            case .response: "📥"
            case .error: "❌"
            case .success: "✅"
            }
            print("\(typeEmoji) \(message)")
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}

/// Debug console view
public struct DebugConsoleView: View {
    @ObservedObject private var logger = DebugLogger.shared
    @State private var showingConsole = false
    @State private var searchText = ""
    
    private var filteredLogs: [DebugLogger.LogEntry] {
        if searchText.isEmpty {
            return logger.logs
        }
        return logger.logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
    }
    
    public var body: some View {
        VStack {
            // Debug button
            Button(action: { showingConsole.toggle() }) {
                HStack {
                    Image(systemName: "terminal")
                    Text("Debug Console (\(logger.logs.count))")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
            .padding()
        }
        .sheet(isPresented: $showingConsole) {
            NavigationView {
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search logs...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding()
                    
                    // Log list
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 8) {
                                ForEach(filteredLogs) { log in
                                    LogRowView(log: log)
                                        .id(log.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: logger.logs.count) { _ in
                            // Auto-scroll to bottom
                            if let lastLog = logger.logs.last {
                                withAnimation {
                                    proxy.scrollTo(lastLog.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Debug Console")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Clear") {
                            logger.clear()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingConsole = false
                        }
                    }
                }
            }
        }
    }
}

struct LogRowView: View {
    let log: DebugLogger.LogEntry
    @State private var expanded = false
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: log.timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                Image(systemName: log.type.icon)
                    .foregroundColor(log.type.color)
                    .font(.caption)
                
                Text(timeString)
                    .font(.caption2)
                    .foregroundColor(.gray)
                
                Text(log.message)
                    .font(.caption)
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
            
            Divider()
        }
        .padding(.horizontal)
    }
}

#Preview {
    DebugConsoleView()
}

