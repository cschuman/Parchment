import Foundation
import os.log

/// Centralized logging for Parchment
public struct Logger {
    
    // MARK: - Log Categories
    
    static let app = os.Logger(subsystem: "com.parchment", category: "app")
    static let rendering = os.Logger(subsystem: "com.parchment", category: "rendering")
    static let file = os.Logger(subsystem: "com.parchment", category: "file")
    static let export = os.Logger(subsystem: "com.parchment", category: "export")
    static let performance = os.Logger(subsystem: "com.parchment", category: "performance")
    static let ui = os.Logger(subsystem: "com.parchment", category: "ui")
    
    // MARK: - Convenience Methods
    
    static func debug(_ message: String, category: os.Logger = app) {
        category.debug("\(message)")
    }
    
    static func info(_ message: String, category: os.Logger = app) {
        category.info("\(message)")
    }
    
    static func warning(_ message: String, category: os.Logger = app) {
        category.warning("\(message)")
    }
    
    static func error(_ message: String, category: os.Logger = app) {
        category.error("\(message)")
    }
    
    static func fault(_ message: String, category: os.Logger = app) {
        category.fault("\(message)")
    }
    
    // MARK: - Performance Logging
    
    static func logPerformance(_ operation: String, time: TimeInterval) {
        performance.info("\(operation) took \(String(format: "%.3f", time))s")
    }
    
    static func measureTime<T>(operation: String, block: () throws -> T) rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        logPerformance(operation, time: elapsed)
        return result
    }
}