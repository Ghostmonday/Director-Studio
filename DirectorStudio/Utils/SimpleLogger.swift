//
//  SimpleLogger.swift
//  DirectorStudio
//
//  PURPOSE: Simple in-memory logger for debugging
//

import Foundation

public class SimpleLogger {
    public static let shared = SimpleLogger()
    private var logs: [String] = []
    private let maxLogs = 100
    
    private init() {}
    
    public func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let entry = "[\(timestamp)] \(message)"
        logs.append(entry)
        if logs.count > maxLogs {
            logs.removeFirst()
        }
        print(entry) // Also print to console
    }
    
    public func getLogs() -> String {
        return logs.joined(separator: "\n")
    }
    
    public func clear() {
        logs.removeAll()
    }
}

