//
//  FocusCommandHandler.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation

// MARK: - focus.set

/// Sets focus to a specific scene entry by ID.
///
/// Usage: `focus.set <id>`
///
/// Pushes the given ID onto the focus stack in SceneRegistry.
public struct FocusSetHandler: CommandHandler {
    public let name = "focus.set"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            guard let id = args.first else {
                return .error("Usage: focus.set <id>")
            }

            guard context.registry.entries[id] != nil else {
                return .error("No entry found with id: \(id)")
            }

            context.registry.pushFocus(id)
            return .ok(
                message: "Focus set to '\(id)'",
                payload: ["focused": id]
            )
        }
    }
}

// MARK: - focus.next

/// Cycles focus to the next entry in registration order.
///
/// Usage: `focus.next`
///
/// If nothing is focused, focuses the first entry. If at the end,
/// wraps around to the first entry.
public struct FocusNextHandler: CommandHandler {
    public let name = "focus.next"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            let sortedIds = context.registry.entries.keys.sorted()
            guard !sortedIds.isEmpty else {
                return .error("No entries to focus")
            }

            let currentId = context.registry.currentFocus
            let nextId: String

            if let current = currentId, let index = sortedIds.firstIndex(of: current) {
                let nextIndex = (index + 1) % sortedIds.count
                nextId = sortedIds[nextIndex]
            } else {
                nextId = sortedIds[0]
            }

            context.registry.pushFocus(nextId)
            return .ok(
                message: "Focus moved to '\(nextId)'",
                payload: ["focused": nextId]
            )
        }
    }
}

// MARK: - Directional Focus Helpers

/// Shared logic for directional focus navigation using the NeighborGraph.
@MainActor
private func navigateFocus(
    direction: String,
    neighborKeyPath: KeyPath<Neighbors, String?>,
    context: CommandContext
) -> CommandResult {
    guard let currentId = context.registry.currentFocus else {
        return .error("No current focus. Use 'focus.set <id>' first.")
    }

    guard let neighbors = context.registry.neighborGraph[currentId] else {
        return .error("No neighbor data for '\(currentId)'. Run a layout first.")
    }

    guard let targetId = neighbors[keyPath: neighborKeyPath] else {
        return .ok(message: "No neighbor \(direction) of '\(currentId)'")
    }

    context.registry.pushFocus(targetId)
    return .ok(
        message: "Focus moved \(direction) to '\(targetId)'",
        payload: ["focused": targetId, "direction": direction]
    )
}

// MARK: - focus.left

/// Moves focus to the left neighbor of the currently focused entry.
///
/// Usage: `focus.left`
public struct FocusLeftHandler: CommandHandler {
    public let name = "focus.left"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            navigateFocus(direction: "left", neighborKeyPath: \.left, context: context)
        }
    }
}

// MARK: - focus.right

/// Moves focus to the right neighbor of the currently focused entry.
///
/// Usage: `focus.right`
public struct FocusRightHandler: CommandHandler {
    public let name = "focus.right"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            navigateFocus(direction: "right", neighborKeyPath: \.right, context: context)
        }
    }
}

// MARK: - focus.up

/// Moves focus to the neighbor above the currently focused entry.
///
/// Usage: `focus.up`
public struct FocusUpHandler: CommandHandler {
    public let name = "focus.up"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            navigateFocus(direction: "up", neighborKeyPath: \.above, context: context)
        }
    }
}

// MARK: - focus.down

/// Moves focus to the neighbor below the currently focused entry.
///
/// Usage: `focus.down`
public struct FocusDownHandler: CommandHandler {
    public let name = "focus.down"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            navigateFocus(direction: "down", neighborKeyPath: \.below, context: context)
        }
    }
}
