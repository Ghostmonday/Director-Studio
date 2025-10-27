//
//  DebugLogger.swift
//  DirectorStudio
//
//  Captures debug logs to a file that can be read programmatically
//

import Foundation

class DebugLogger {
    static let shared = DebugLogger()
    
    private let logFileURL: URL
    private let fileHandle: FileHandle?
    
    private init() {
        // Create log file in Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        logFileURL = documentsPath.appendingPathComponent("debug_logs.txt")
        
        // Create or clear the file
        if !FileManager.default.fileExists(atPath: logFileURL.path) {
            FileManager.default.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        } else {
            // Clear existing content
            try? "".write(to: logFileURL, atomically: true, encoding: .utf8)
        }
        
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        
        log("📱 DebugLogger initialized at: \(logFileURL.path)")
    }
    
    func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        
        // Print to console
        print(logMessage, terminator: "")
        
        // Write to file
        if let data = logMessage.data(using: .utf8) {
            fileHandle?.write(data)
        }
    }
    
    func getLogs() -> String {
        return (try? String(contentsOf: logFileURL, encoding: .utf8)) ?? "No logs available"
    }
    
    func clearLogs() {
        try? "".write(to: logFileURL, atomically: true, encoding: .utf8)
        log("🗑️ Logs cleared")
    }
    
    deinit {
        try? fileHandle?.close()
    }
}

// Global logging function
func LOG(_ message: String) {
    #if DEBUG
    DebugLogger.shared.log(message)
    #endif
}

