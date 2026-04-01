//
//  SceneCommandHandler.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation

// MARK: - scene.list

/// Lists all scene entries with summary information.
///
/// Usage: `scene.list`
///
/// Similar to `grid.list` but framed as a scene-level query.
/// Returns entry count and names.
public struct SceneListHandler: CommandHandler {
    public let name = "scene.list"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        let entries = context.registry.entries
        let ids = entries.keys.sorted()

        var payload: [String: String] = [
            "count": "\(ids.count)",
            "focused": context.registry.currentFocus ?? "none",
        ]

        for id in ids {
            if let entry = entries[id] {
                payload[id] = entry.content.name
            }
        }

        return .ok(message: "Scene has \(ids.count) entries", payload: payload)
    }
}

// MARK: - scene.info

/// Returns detailed scene-level information: entry count, focus state,
/// allocated group count, neighbor graph size.
///
/// Usage: `scene.info`
public struct SceneInfoHandler: CommandHandler {
    public let name = "scene.info"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        let entryCount = context.registry.entries.count
        let neighborCount = context.registry.neighborGraph.count
        let groupCount = context.groupTransforms.allocatedGroupCount

        return .ok(
            message: "Scene info",
            payload: [
                "entryCount": "\(entryCount)",
                "focusStackDepth": "\(context.registry.focusStack.count)",
                "currentFocus": context.registry.currentFocus ?? "none",
                "neighborGraphSize": "\(neighborCount)",
                "allocatedGroups": "\(groupCount)",
            ]
        )
    }
}

// MARK: - scene.snapshot

/// Captures a read-only snapshot of all entry positions.
///
/// Usage: `scene.snapshot`
///
/// Returns each entry's current transform position from the CPU shadow.
public struct SceneSnapshotHandler: CommandHandler {
    public let name = "scene.snapshot"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        var payload: [String: String] = [:]

        for (id, entry) in context.registry.entries {
            let transform = context.groupTransforms.getTransform(entry.groupId)
            let pos = transform.columns.3
            payload[id] = "(\(pos.x), \(pos.y), \(pos.z))"
        }

        payload["count"] = "\(context.registry.entries.count)"
        return .ok(message: "Scene snapshot captured", payload: payload)
    }
}

// MARK: - scene.clear

/// Removes all entries from the scene registry.
///
/// Usage: `scene.clear`
///
/// This is destructive -- all entries are unregistered and their
/// group IDs recycled.
public struct SceneClearHandler: CommandHandler {
    public let name = "scene.clear"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        let count = context.registry.entries.count
        let ids = Array(context.registry.entries.keys)

        for id in ids {
            context.registry.unregister(id: id)
        }

        return .ok(
            message: "Cleared \(count) entries from scene",
            payload: ["removed": "\(count)"]
        )
    }
}
