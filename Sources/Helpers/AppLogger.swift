//
//  File.swift
//  MyLibrary
//
//  Created by Oskar Groth on 2025-05-13.
//

import Foundation
import os
import OSLog

/// AppLogger provides a simple wrapper around OSLog's Logger
/// with convenience functions for consistent logging throughout the app.
public enum AppLogger {
    fileprivate static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.cindori.app", category: "main")

    fileprivate static var fileEmojis: [String: String] = [:]

    fileprivate static let defaultEmojis: [LogLevel: String] = [
        .debug: "🐞",
        .notice: "📢",
        .warning: "⚠️",
        .error: "❌",
        .critical: "🔥"
    ]

    public enum LogLevel {
        case debug, info, notice, warning, error, critical
    }

    public static func registerEmoji(_ emoji: String, for filePath: String = #file) {
        fileEmojis[filePath] = emoji
    }

    public static func emojiForFile(_ filePath: String) -> String? {
        return fileEmojis[filePath]
    }

    fileprivate static func log(_ level: LogLevel, _ message: String, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let emoji = AppLogger.emojiForFile(file) ?? AppLogger.defaultEmojis[level] ?? ""

        let context: String
        switch level {
        case .info, .notice:
            context = emoji.isEmpty ? "" : "\(emoji) "
        default:
            context = emoji.isEmpty ? "" : "\(emoji) [\(fileName):\(line)] \(function) "
        }

        let fullMessage = "\(context)\(message)"

        switch level {
            case .debug:
                logger.debug("\(fullMessage, privacy: .public)")
            case .info:
                logger.info("\(fullMessage, privacy: .public)")
            case .notice:
                logger.notice("\(fullMessage, privacy: .public)")
            case .warning:
                logger.warning("\(fullMessage, privacy: .public)")
            case .error:
                logger.error("\(fullMessage, privacy: .public)")
            case .critical:
                logger.fault("\(fullMessage, privacy: .public)")
        }
    }
}

// MARK: - Global convenience functions

public func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.log(.debug, message, file: file, function: function, line: line)
}

public func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.log(.info, message, file: file, function: function, line: line)
}

public func logNotice(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.log(.notice, message, file: file, function: function, line: line)
}

public func logWarn(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.log(.warning, message, file: file, function: function, line: line)
}

public func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.log(.error, message, file: file, function: function, line: line)
}

public func logError(_ error: Error, file: String = #file, function: String = #function, line: Int = #line) {
    let typeName = String(describing: type(of: error))
    let customDescription = String(describing: error)
    let localizedDescription = error.localizedDescription
    let nsErrorDescription = (error as NSError).description

    let errorMessage: String

    if customDescription != typeName {
        errorMessage = "\(typeName): \(customDescription) – \(localizedDescription)"
    } else {
        errorMessage = "\(typeName): \(nsErrorDescription)"
    }
    AppLogger.log(.error, errorMessage, file: file, function: function, line: line)
}

public func logCritical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    AppLogger.log(.critical, message, file: file, function: function, line: line)
}

public func catchAndLogErrors(file: String = #file, function: String = #function, line: Int = #line, _ block: () throws -> Void) {
    do {
        try block()
    } catch {
        logError(error, file: file, function: function, line: line)
    }
}

public func registerLogEmoji(_ emoji: String, file: String = #file) {
    AppLogger.registerEmoji(emoji, for: file)
}

// MARK: Log Store Methods
extension AppLogger {
    /// Fetch the last `hours` of unified logs matching a raw predicate.
    ///
    /// - Parameters:
    ///   - predicate: An NSPredicate-format string, e.g.
    ///       `process == "MyAppExecutableName"` or
    ///       `subsystem == "com.mycompany.myapp" AND eventType >= error`
    ///   - hours: How many hours back to include.
    /// - Returns: One log‐line per entry, in syslog style.
    public static func fetchLogs(
        predicate: String,
        last hours: Int,
        maxEntries: Int? = nil
    ) async throws -> [String] {
        let args = [
            "show",
            "--style", "syslog",
            "--debug",
            "--info",
            "--predicate", predicate,
            "--last", "\(hours)h"
        ]
        let logTask = Process()
        logTask.launchPath = "/usr/bin/log"
        logTask.arguments = args

        let logPipe = Pipe()
        logTask.standardOutput = logPipe
        logTask.standardError  = logPipe
        
        if let count = maxEntries {
            // Build the `tail` command and pipe input from log
            let tailTask = Process()
            tailTask.executableURL = URL(fileURLWithPath: "/usr/bin/tail")
            tailTask.arguments = ["-n", "\(count)"]
            tailTask.standardInput = logPipe

            let tailPipe = Pipe()
            tailTask.standardOutput = tailPipe
            tailTask.standardError  = tailPipe

            try logTask.run()
            try tailTask.run()

            let data = try tailPipe.fileHandleForReading.readToEnd()
            logTask.terminate()
            tailTask.terminate()

            guard let output = data.flatMap({ String(data: $0, encoding: .utf8) }), !output.isEmpty else {
                return []
            }
            return output.split(whereSeparator: \.isNewline).map(String.init)
        } else {
            try logTask.run()

            let data = try logPipe.fileHandleForReading.readToEnd()
            logTask.terminate()

            guard let output = data.flatMap({ String(data: $0, encoding: .utf8) }), !output.isEmpty else {
                return []
            }
            return output.split(whereSeparator: \.isNewline).map(String.init)
        }
    }

    private static func formatLevel(_ level: OSLogEntryLog.Level) -> String {
        switch level {
            case .undefined: return "UNDEFINED"
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .notice: return "NOTICE"
            case .error: return "ERROR"
            case .fault: return "FAULT"
            @unknown default: return "UNKNOWN"
        }
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}
