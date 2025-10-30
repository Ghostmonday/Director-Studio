import Foundation

final class CrashReporter {
    static let shared = CrashReporter()
    
    private var isConfigured = false
    
    private init() {
        setup()
    }
    
    private func setup() {
        NSSetUncaughtExceptionHandler { exception in
            CrashReporter.shared.logException(exception)
        }
        
        signal(SIGABRT) { _ in
            CrashReporter.shared.logCrash("SIGABRT")
        }
        
        signal(SIGILL) { _ in
            CrashReporter.shared.logCrash("SIGILL")
        }
        
        signal(SIGSEGV) { _ in
            CrashReporter.shared.logCrash("SIGSEGV")
        }
        
        signal(SIGFPE) { _ in
            CrashReporter.shared.logCrash("SIGFPE")
        }
        
        signal(SIGBUS) { _ in
            CrashReporter.shared.logCrash("SIGBUS")
        }
        
        signal(SIGPIPE) { _ in
            CrashReporter.shared.logCrash("SIGPIPE")
        }
        
        isConfigured = true
    }
    
    private func logException(_ exception: NSException) {
        let report = [
            "type": "exception",
            "name": exception.name.rawValue,
            "reason": exception.reason ?? "Unknown",
            "callStack": exception.callStackSymbols.joined(separator: "\n")
        ]
        
        sendReport(report)
    }
    
    private func logCrash(_ signal: String) {
        let report = [
            "type": "crash",
            "signal": signal,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        sendReport(report)
    }
    
    func logError(_ error: Error, context: [String: Any] = [:]) {
        let report = [
            "type": "error",
            "message": error.localizedDescription,
            "context": context,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        sendReport(report)
    }
    
    private func sendReport(_ report: [String: Any]) {
        let data = try? JSONSerialization.data(withJSONObject: report)
        UserDefaults.standard.set(data, forKey: "last_crash_report")
    }
}

