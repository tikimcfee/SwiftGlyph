//
//  SelectionCommandHandler.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation

// MARK: - select.set

/// Sets focus/selection to a specific entry, replacing the current focus stack.
///
/// Usage: `select.set <id>`
///
/// Unlike `focus.set` which pushes onto the stack, this replaces
/// the entire stack with a single entry.
public struct SelectSetHandler: CommandHandler {
    public let name = "select.set"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            guard let id = args.first else {
                return .error("Usage: select.set <id>")
            }

            guard context.registry.entries[id] != nil else {
                return .error("No entry found with id: \(id)")
            }

            context.registry.focusStack = [id]
            return .ok(
                message: "Selection set to '\(id)'",
                payload: ["selected": id]
            )
        }
    }
}

// MARK: - select.clear

/// Clears the selection / focus stack entirely.
///
/// Usage: `select.clear`
public struct SelectClearHandler: CommandHandler {
    public let name = "select.clear"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            context.registry.focusStack = []
            return .ok(message: "Selection cleared")
        }
    }
}

// MARK: - select.toggle

/// Toggles an entry in the focus stack.
///
/// Usage: `select.toggle <id>`
///
/// If the entry is already in the focus stack, removes it.
/// If not, pushes it.
public struct SelectToggleHandler: CommandHandler {
    public let name = "select.toggle"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            guard let id = args.first else {
                return .error("Usage: select.toggle <id>")
            }

            guard context.registry.entries[id] != nil else {
                return .error("No entry found with id: \(id)")
            }

            if context.registry.focusStack.contains(id) {
                context.registry.focusStack.removeAll { $0 == id }
                return .ok(
                    message: "Deselected '\(id)'",
                    payload: ["action": "deselected", "id": id]
                )
            } else {
                context.registry.focusStack.append(id)
                return .ok(
                    message: "Selected '\(id)'",
                    payload: ["action": "selected", "id": id]
                )
            }
        }
    }
}
