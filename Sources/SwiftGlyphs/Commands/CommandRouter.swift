//
//  CommandRouter.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation

/// Central command dispatch for the application.
///
/// `@MainActor class` (not actor) because every `CommandHandler` touches
/// `@MainActor`-isolated state. An actor router would force every handler
/// to hop to `@MainActor` internally, producing two hops for zero benefit.
///
/// Emits `AsyncStream<CommandEvent>` so external consumers (WebSocket relay,
/// CLI, agents) can observe all command executions.
///
/// Commands are dot-namespaced strings: "grid.move", "layout.apply", etc.
/// The router parses the command string by splitting on whitespace -- the
/// first token is the command name, the rest are arguments.
@MainActor
public final class CommandRouter {

    // MARK: - State

    private var handlers: [String: any CommandHandler] = [:]
    private let context: CommandContext

    // MARK: - Event Stream

    /// Stream of all executed command events for external consumers.
    public let eventStream: AsyncStream<CommandEvent>
    private let eventContinuation: AsyncStream<CommandEvent>.Continuation

    // MARK: - Init

    /// `nonisolated` to allow creation from non-isolated contexts (e.g., static let).
    nonisolated public init(context: CommandContext) {
        self.context = context

        let (stream, continuation) = AsyncStream<CommandEvent>.makeStream()
        self.eventStream = stream
        self.eventContinuation = continuation
    }

    deinit {
        eventContinuation.finish()
    }

    // MARK: - Handler Registration

    /// Registers a handler for its declared command name.
    /// Overwrites any previously registered handler with the same name.
    public func register(_ handler: any CommandHandler) {
        handlers[handler.name] = handler
    }

    /// Unregisters the handler for the given command name.
    public func unregister(name: String) {
        handlers.removeValue(forKey: name)
    }

    // MARK: - Execution

    /// Parses and executes a full command string.
    /// Format: `"command.name arg1 arg2 arg3"`
    ///
    /// - Parameter command: The full command string to parse and execute.
    /// - Returns: The result of command execution.
    public func execute(_ command: String) async -> CommandResult {
        let parts = command
            .trimmingCharacters(in: .whitespaces)
            .split(separator: " ")
            .map(String.init)

        guard let name = parts.first else {
            return .error("Empty command")
        }

        let args = Array(parts.dropFirst())
        return await execute(name, args: args)
    }

    /// Executes a command by name with pre-parsed arguments.
    ///
    /// - Parameters:
    ///   - command: The dot-namespaced command name.
    ///   - args: Pre-parsed arguments.
    /// - Returns: The result of command execution.
    public func execute(_ command: String, args: [String]) async -> CommandResult {
        guard let handler = handlers[command] else {
            return .error("Unknown command: \(command)")
        }

        let result = await handler.execute(args: args, context: context)

        let event = CommandEvent(
            command: command,
            args: args,
            result: result
        )
        eventContinuation.yield(event)

        return result
    }

    // MARK: - Introspection

    /// All registered command names, sorted.
    public var registeredCommands: [String] {
        handlers.keys.sorted()
    }

    /// Returns command names matching a dot-namespace prefix.
    /// For example, prefix "grid." returns ["grid.create", "grid.move", "grid.remove"].
    public func commands(matchingPrefix prefix: String) -> [String] {
        handlers.keys
            .filter { $0.hasPrefix(prefix) }
            .sorted()
    }
}
