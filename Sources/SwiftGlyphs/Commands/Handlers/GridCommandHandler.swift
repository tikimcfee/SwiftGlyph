//
//  GridCommandHandler.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import simd
import MetalLink

// MARK: - grid.list

/// Lists all registered scene entries.
///
/// Usage: `grid.list`
///
/// Returns a JSON payload with entry IDs, names, and visibility.
public struct GridListHandler: CommandHandler {
    public let name = "grid.list"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            let entries = context.registry.entries
            guard !entries.isEmpty else {
                return .ok(message: "No grids registered", payload: ["count": "0"])
            }

            var payload: [String: String] = ["count": "\(entries.count)"]
            for (id, entry) in entries.sorted(by: { $0.key < $1.key }) {
                let visibility = entry.isVisible ? "visible" : "hidden"
                payload[id] = "\(entry.content.name) [\(visibility)] groupId=\(entry.groupId)"
            }
            return .ok(message: "\(entries.count) grid(s) registered", payload: payload)
        }
    }
}

// MARK: - grid.info

/// Returns detailed information about a single grid entry.
///
/// Usage: `grid.info <id>`
public struct GridInfoHandler: CommandHandler {
    public let name = "grid.info"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            guard let id = args.first else {
                return .error("Usage: grid.info <id>")
            }

            guard let entry = context.registry.entries[id] else {
                return .error("No entry found with id: \(id)")
            }

            let transform = context.groupTransforms.getTransform(entry.groupId)
            let position = transform.columns.3

            return .ok(
                message: "Grid '\(id)': \(entry.content.name)",
                payload: [
                    "id": id,
                    "name": entry.content.name,
                    "groupId": "\(entry.groupId)",
                    "visible": "\(entry.isVisible)",
                    "x": "\(position.x)",
                    "y": "\(position.y)",
                    "z": "\(position.z)",
                ]
            )
        }
    }
}

// MARK: - grid.create

/// Creates a new scene entry. Currently a stub that registers a placeholder.
///
/// Usage: `grid.create <id> [name]`
///
/// The actual content creation (loading source, building glyphs) is deferred.
/// This handler registers the entry in the scene registry so that subsequent
/// commands (move, hide, layout) can reference it.
public struct GridCreateHandler: CommandHandler {
    public let name = "grid.create"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            guard let id = args.first else {
                return .error("Usage: grid.create <id> [name]")
            }

            if context.registry.entries[id] != nil {
                return .error("Entry already exists with id: \(id)")
            }

            let displayName = args.count >= 2 ? args[1] : id
            let placeholder = PlaceholderContent(name: displayName)
            let entry = context.registry.register(id: id, content: placeholder)

            return .ok(
                message: "Created grid '\(id)' with groupId \(entry.groupId)",
                payload: [
                    "id": id,
                    "groupId": "\(entry.groupId)",
                ]
            )
        }
    }
}

// MARK: - grid.move

/// Moves a grid to an absolute position via GroupTransformManager.
///
/// Usage: `grid.move <id> <x> <y> <z>`
public struct GridMoveHandler: CommandHandler {
    public let name = "grid.move"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        guard args.count >= 4,
              let x = Float(args[1]),
              let y = Float(args[2]),
              let z = Float(args[3])
        else {
            return .error("Usage: grid.move <id> <x> <y> <z>")
        }

        let id = args[0]
        return await MainActor.run {
            guard let entry = context.registry.entries[id] else {
                return .error("No entry found with id: \(id)")
            }

            context.groupTransforms.setOffset(entry.groupId, SIMD3<Float>(x, y, z))

            return .ok(
                message: "Moved '\(id)' to (\(x), \(y), \(z))",
                payload: ["id": id, "x": "\(x)", "y": "\(y)", "z": "\(z)"]
            )
        }
    }
}

// MARK: - grid.hide

/// Hides a grid by marking it not visible.
///
/// Usage: `grid.hide <id>`
///
/// Sets `SceneEntry.isVisible = false`. The render loop is expected to
/// skip entries that are not visible.
public struct GridHideHandler: CommandHandler {
    public let name = "grid.hide"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            guard let id = args.first else {
                return .error("Usage: grid.hide <id>")
            }

            guard let entry = context.registry.entries[id] else {
                return .error("No entry found with id: \(id)")
            }

            entry.isVisible = false
            return .ok(message: "Grid '\(id)' hidden")
        }
    }
}

// MARK: - grid.show

/// Shows a previously hidden grid.
///
/// Usage: `grid.show <id>`
public struct GridShowHandler: CommandHandler {
    public let name = "grid.show"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            guard let id = args.first else {
                return .error("Usage: grid.show <id>")
            }

            guard let entry = context.registry.entries[id] else {
                return .error("No entry found with id: \(id)")
            }

            entry.isVisible = true
            return .ok(message: "Grid '\(id)' shown")
        }
    }
}

// MARK: - grid.remove

/// Removes a grid from the scene registry entirely.
///
/// Usage: `grid.remove <id>`
///
/// Unregisters the entry and recycles its group ID.
public struct GridRemoveHandler: CommandHandler {
    public let name = "grid.remove"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        await MainActor.run {
            guard let id = args.first else {
                return .error("Usage: grid.remove <id>")
            }

            guard context.registry.entries[id] != nil else {
                return .error("No entry found with id: \(id)")
            }

            context.registry.unregister(id: id)
            return .ok(message: "Grid '\(id)' removed")
        }
    }
}

// MARK: - Placeholder Content

/// Lightweight placeholder for grids created via command before
/// actual content (source file, syntax tree) is loaded.
private final class PlaceholderContent: SceneEntryContent {
    let name: String
    init(name: String) { self.name = name }
}
