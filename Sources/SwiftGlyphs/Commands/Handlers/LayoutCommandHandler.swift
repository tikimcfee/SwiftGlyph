//
//  LayoutCommandHandler.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import simd
import MetalLink

// MARK: - layout.apply

/// Applies a named layout strategy to all (or a subset of) scene entries.
///
/// Usage: `layout.apply <strategy> [entryId1 entryId2 ...]`
///
/// Supported strategies: `grid`, `hierarchical`, `force`.
/// If no entry IDs are given, applies to all entries in the registry.
public struct LayoutApplyHandler: CommandHandler {
    public let name = "layout.apply"

    /// Known layout managers keyed by strategy name.
    /// Handlers are stateless so we build fresh instances each time.
    private func manager(for strategy: String) -> (any LayoutManager)? {
        switch strategy {
        case "grid":        return GridLayoutManager()
        case "hierarchical": return HierarchicalLayoutManager()
        default:            return nil
        }
    }

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        guard let strategy = args.first else {
            return .error("Usage: layout.apply <strategy> [entryId ...]")
        }

        guard let layoutManager = manager(for: strategy) else {
            return .error("Unknown layout strategy: \(strategy). Available: grid, hierarchical")
        }

        let entryIds = Array(args.dropFirst())

        let (entries, positionables) = await MainActor.run {
            let entries: [SceneEntry]

            if entryIds.isEmpty {
                entries = Array(context.registry.entries.values)
            } else {
                entries = entryIds.compactMap { context.registry.entries[$0] }
            }

            let positionables = entries.map { entry in
                SimplePositionable(
                    id: entry.id,
                    groupId: entry.groupId,
                    bounds: boundsForEntry(entry, context: context)
                )
            }

            return (entries, positionables)
        }

        if !entryIds.isEmpty && entries.isEmpty {
            return .error("No matching entries found for provided IDs")
        }

        let result = layoutManager.layout(entries: positionables)
        await layoutManager.apply(
            result: result,
            transforms: context.groupTransforms,
            registry: context.registry
        )

        return .ok(
            message: "Applied '\(strategy)' layout to \(entries.count) entries",
            payload: ["strategy": strategy, "count": "\(entries.count)"]
        )
    }

    private func boundsForEntry(_ entry: SceneEntry, context: CommandContext) -> LFloat3 {
        // Default bounds estimate. Real bounds would come from the content's
        // glyph collection once wired. For now use a reasonable placeholder.
        LFloat3(100, 60, 1)
    }
}

// MARK: - layout.grid

/// Shorthand for `layout.apply grid`.
///
/// Usage: `layout.grid [entryId ...]`
public struct LayoutGridHandler: CommandHandler {
    public let name = "layout.grid"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        let inner = LayoutApplyHandler()
        return await inner.execute(args: ["grid"] + args, context: context)
    }
}

// MARK: - layout.hierarchical

/// Shorthand for `layout.apply hierarchical`.
///
/// Usage: `layout.hierarchical [entryId ...]`
public struct LayoutHierarchicalHandler: CommandHandler {
    public let name = "layout.hierarchical"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        let inner = LayoutApplyHandler()
        return await inner.execute(args: ["hierarchical"] + args, context: context)
    }
}

// MARK: - layout.force

/// Placeholder for force-directed layout.
///
/// Usage: `layout.force [entryId ...]`
///
/// Force layout requires iterative simulation. This handler kicks off
/// the computation and returns a `.pending` result. A future event
/// will signal completion.
public struct LayoutForceHandler: CommandHandler {
    public let name = "layout.force"

    public func execute(args: [String], context: CommandContext) async -> CommandResult {
        // Force layout is computationally expensive and iterative.
        // For now, return pending to indicate this is not yet wired.
        return .pending("Force layout not yet integrated. Use 'layout.grid' or 'layout.hierarchical'.")
    }
}

// MARK: - SimplePositionable

/// Lightweight adapter that conforms existing `SceneEntry` data to `Positionable`.
struct SimplePositionable: Positionable {
    let id: String
    let groupId: UInt16
    let bounds: LFloat3
}
