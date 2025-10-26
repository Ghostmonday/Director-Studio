//
//  AgentDevMode.swift
//  DirectorStudio
//
//  Agent-only dev mode control
//

import Foundation

/// Agent-only dev mode control
/// This file allows the AI agent to control dev mode without UI access
public enum AgentDevMode {
    
    /// Enable dev mode for testing (agent-only)
    public static func enable() {
        guard ProcessInfo.processInfo.environment["AGENT_CONTROL"] != nil else {
            print("❌ Dev mode can only be enabled by the agent")
            return
        }
        
        // Set dev mode flags
        UserDefaults.standard.set(true, forKey: "DEV_MODE_ENABLED")
        UserDefaults.standard.set(Date(), forKey: "DEV_MODE_PASSCODE_TIMESTAMP")
        
        // Post notification
        NotificationCenter.default.post(name: .creditsDidChange, object: nil)
        
        print("✅ Dev mode enabled by agent")
    }
    
    /// Disable dev mode (agent-only)
    public static func disable() {
        UserDefaults.standard.set(false, forKey: "DEV_MODE_ENABLED")
        UserDefaults.standard.removeObject(forKey: "DEV_MODE_PASSCODE_TIMESTAMP")
        
        NotificationCenter.default.post(name: .creditsDidChange, object: nil)
        
        print("✅ Dev mode disabled by agent")
    }
    
    /// Check if dev mode is active
    public static var isActive: Bool {
        return UserDefaults.standard.bool(forKey: "DEV_MODE_ENABLED")
    }
}
