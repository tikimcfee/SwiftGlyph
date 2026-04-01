//
//  CommandHandler.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import MetalLink

/// Protocol for command handlers registered with `CommandRouter`.
///
/// `Sendable` but NOT `@MainActor`-isolated by default. Handlers that need
/// main actor annotate themselves. Handlers doing pure computation (parsing,
/// search indexing) can be `nonisolated`.
///
/// The router calls `execute` from `@MainActor` context. Handlers that do
/// heavy work (file loading, syntax highlighting) should use `Task.detached`
/// internally and return a `.pending` result.
public protocol CommandHandler: Sendable {
    /// Dot-namespaced command name (e.g., "grid.move", "layout.apply").
    var name: String { get }

    /// Executes the command with the given arguments.
    /// - Parameters:
    ///   - args: Arguments parsed from the command string (everything after the command name).
    ///   - context: Provides access to SceneRegistry, GroupTransformManager, MetalContext.
    /// - Returns: The result of command execution.
    func execute(args: [String], context: CommandContext) async -> CommandResult
}

/// Holds references to all major subsystems that command handlers may need.
/// Created once at the composition root and shared by all handlers via the router.
///
/// `@MainActor` because its contents (`SceneRegistry`, `GroupTransformManager`,
/// `MetalContext`) are all `@MainActor`-isolated.
@MainActor
public final class CommandContext {
    public let registry: SceneRegistry
    public let groupTransforms: GroupTransformManager
    public let metalContext: MetalContext

    // Future additions (added as needed, not speculatively):
    // public var camera: DebugCamera
    // public var gridStore: GridStore

    /// `nonisolated` to allow creation from non-isolated contexts (e.g., static let).
    nonisolated public init(
        registry: SceneRegistry,
        groupTransforms: GroupTransformManager,
        metalContext: MetalContext
    ) {
        self.registry = registry
        self.groupTransforms = groupTransforms
        self.metalContext = metalContext
    }
}
