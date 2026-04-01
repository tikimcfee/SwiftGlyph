//
//  SceneRegistry.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import Observation
import MetalLink

/// Central registry of all scene entries (grids, windows, etc.).
///
/// `@Observable` for fine-grained SwiftUI invalidation -- views read stored
/// properties directly (e.g., `registry.entries`), triggering re-render only
/// when those specific properties change.
///
/// `@MainActor` because all mutations come through `CommandRouter` (also
/// `@MainActor`), and reads happen from SwiftUI views and the render loop.
///
/// Owns the `NeighborGraph`, which persists between layouts so keyboard
/// navigation works without re-running layout.
@Observable
@MainActor
public final class SceneRegistry {

    // MARK: - Stored Properties (observable)

    /// All registered scene entries, keyed by entry ID.
    public var entries: [String: SceneEntry] = [:]

    /// Stack of focused entry IDs. The last element is the current focus.
    public var focusStack: [String] = []

    /// ID of the entry currently under the pointer, if any.
    public var hoveredNode: String? = nil

    /// Directional adjacency graph, updated by layout application.
    public var neighborGraph: NeighborGraph = [:]

    // MARK: - Dependencies

    private let groupManager: GroupTransformManager

    // MARK: - Init

    /// `nonisolated` to allow creation from non-isolated contexts (e.g., static let).
    nonisolated public init(groupManager: GroupTransformManager) {
        self.groupManager = groupManager
    }

    // MARK: - Registration

    /// Registers content in the scene, allocating a GPU group ID.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this entry.
    ///   - content: The content object (e.g., `CodeGrid`).
    /// - Returns: The created `SceneEntry` with its allocated `groupId`.
    @discardableResult
    public func register(id: String, content: any SceneEntryContent) -> SceneEntry {
        let groupId = groupManager.allocateGroupId()
        let entry = SceneEntry(id: id, groupId: groupId, content: content)
        entries[id] = entry
        return entry
    }

    /// Removes an entry from the scene and recycles its group ID.
    public func unregister(id: String) {
        guard let entry = entries.removeValue(forKey: id) else { return }
        groupManager.recycleGroupId(entry.groupId)

        // Clean up focus stack references
        focusStack.removeAll { $0 == id }

        // Clean up neighbor references
        neighborGraph.removeValue(forKey: id)

        if hoveredNode == id {
            hoveredNode = nil
        }
    }

    // MARK: - Focus

    /// The currently focused entry ID, if any.
    public var currentFocus: String? {
        focusStack.last
    }

    /// Pushes an entry ID onto the focus stack.
    public func pushFocus(_ id: String) {
        focusStack.append(id)
    }

    /// Pops the current focus, returning to the previous one.
    @discardableResult
    public func popFocus() -> String? {
        focusStack.popLast()
    }
}
