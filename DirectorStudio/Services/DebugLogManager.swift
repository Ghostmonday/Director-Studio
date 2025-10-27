//
//  DebugLogManager.swift
//  DirectorStudio
//
//  PURPOSE: Simple debug log manager that stores logs in memory
//

import Foundation
import SwiftUI

/// Simple debug log manager
public class DebugLogManager: ObservableObject {
    public static let shared = DebugLogManager()
    
    @Published public var logs: [String] = []
    private let maxLogs = 100
    
    private init() {
        log("🚀 Debug Log Manager Started")
    }
    
    public func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logEntry = "[\(timestamp)] \(message)"
        
        DispatchQueue.main.async {
            self.logs.append(logEntry)
            if self.logs.count > self.maxLogs {
                self.logs.removeFirst(self.logs.count - self.maxLogs)
            }
        }
        
        // Also print to console
        print(logEntry)
    }
    
    public func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    public func exportLogs() -> String {
        return logs.joined(separator: "\n")
    }
}

/// Debug log display view
public struct DebugLogView: View {
    @ObservedObject private var logManager = DebugLogManager.shared
    @State private var showingExport = false
    
    public var body: some View {
        NavigationView {
            VStack {
                // Log count
                HStack {
                    Text("\(logManager.logs.count) logs")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding(.horizontal)
                
                // Log list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(logManager.logs.enumerated()), id: \.offset) { index, log in
                                Text(log)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal)
                                    .id(index)
                            }
                        }
                    }
                    .onChange(of: logManager.logs.count) { _ in
                        // Auto-scroll to bottom
                        if let lastIndex = logManager.logs.indices.last {
                            withAnimation {
                                proxy.scrollTo(lastIndex, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Export button
                Button(action: { showingExport = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Logs")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        logManager.clear()
                    }
                }
            }
        }
        .sheet(isPresented: $showingExport) {
            ShareSheet(items: [logManager.exportLogs()])
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
    DebugLogView()
}

