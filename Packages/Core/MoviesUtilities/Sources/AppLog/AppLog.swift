//
//  AppLog.swift
//  MoviesUtilities
//
//  Created by User on 9/15/25.
//

import Foundation
import OSLog

/// Centralized OSLog.Logger instances for structured logging across the Movies app.
/// Feature-oriented categories provide better organization and filtering.
public enum AppLog {
    private static let subsystem: String = Bundle.main.bundleIdentifier ?? "Movies"

    // Feature-oriented logger categories
    public static let network = Logger(subsystem: subsystem, category: "Network")
    public static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    public static let home = Logger(subsystem: subsystem, category: "Home")
    public static let search = Logger(subsystem: subsystem, category: "Search")
    public static let favorites = Logger(subsystem: subsystem, category: "Favorites")
    public static let details = Logger(subsystem: subsystem, category: "Details")
    public static let navigation = Logger(subsystem: subsystem, category: "Navigation")
    public static let designSystem = Logger(subsystem: subsystem, category: "DesignSystem")
    public static let general = Logger(subsystem: subsystem, category: "General")
}

// MARK: - Logger Convenience Methods (restored per project preference)
public extension Logger {
    /// Log an info message (public by default)
    func info(_ message: String) {
        self.log(level: .info, "\(message, privacy: .public)")
    }

    /// Log a debug message (public by default)
    func debug(_ message: String) {
        self.log(level: .debug, "\(message, privacy: .public)")
    }

    /// Log a warning message (public by default)
    func warning(_ message: String) {
        self.log(level: .default, "\(message, privacy: .public)")
    }

    /// Log an error message (public by default)
    func error(_ message: String) {
        self.log(level: .error, "\(message, privacy: .public)")
    }

    /// Log a message with default level (public by default)
    func log(_ message: String) {
        self.log(level: .info, "\(message, privacy: .public)")
    }

    /// Secure logging variants (private by default)
    func secureInfo(_ message: String) { self.log(level: .info, "\(message, privacy: .private)") }
    func secureDebug(_ message: String) { self.log(level: .debug, "\(message, privacy: .private)") }
    func secureWarning(_ message: String) { self.log(level: .default, "\(message, privacy: .private)") }
    func secureError(_ message: String) { self.log(level: .error, "\(message, privacy: .private)") }
}
