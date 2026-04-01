//
//  CommandResult.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation

/// Result of executing a command through `CommandRouter`.
/// `Codable` and `Sendable` so it can be serialized over WebSocket/Unix socket
/// for CLI and agent consumers.
public struct CommandResult: Codable, Sendable, Equatable {

    public enum Status: String, Codable, Sendable {
        case success
        case error
        case pending
    }

    public let status: Status

    /// Optional JSON-serializable payload data.
    /// For simple cases, use key-value pairs encoded as `[String: String]`.
    public let payload: [String: String]?

    /// Human-readable message (error description, status info, etc.).
    public let message: String?

    public init(
        status: Status,
        payload: [String: String]? = nil,
        message: String? = nil
    ) {
        self.status = status
        self.payload = payload
        self.message = message
    }

    // MARK: - Convenience Factories

    public static func ok(
        message: String? = nil,
        payload: [String: String]? = nil
    ) -> CommandResult {
        CommandResult(status: .success, payload: payload, message: message)
    }

    public static func error(_ message: String) -> CommandResult {
        CommandResult(status: .error, message: message)
    }

    public static func pending(_ message: String? = nil) -> CommandResult {
        CommandResult(status: .pending, message: message)
    }
}

/// Event emitted by `CommandRouter` after each command execution.
/// External consumers (WebSocket relay, CLI) subscribe to the event stream.
public struct CommandEvent: Sendable {
    public let command: String
    public let args: [String]
    public let result: CommandResult
    public let timestamp: Date

    public init(
        command: String,
        args: [String],
        result: CommandResult,
        timestamp: Date = Date()
    ) {
        self.command = command
        self.args = args
        self.result = result
        self.timestamp = timestamp
    }
}
