//
//  LayoutManager.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import simd
import MetalLink

/// Describes a positionable scene entry for layout purposes.
public protocol Positionable {
    var id: String { get }
    var groupId: UInt16 { get }
    var bounds: LFloat3 { get }
}

/// Result of a layout computation.
/// Contains positions for each entry and the computed neighbor adjacency graph.
public struct LayoutResult {
    /// Computed positions keyed by entry ID.
    public let positions: [String: LFloat3]

    /// Directional adjacency computed during layout.
    public let neighbors: NeighborGraph

    public init(
        positions: [String: LFloat3],
        neighbors: NeighborGraph
    ) {
        self.positions = positions
        self.neighbors = neighbors
    }
}

/// Protocol for layout strategies.
///
/// Layout managers compute positions for a set of positionable entries,
/// then write results to the GPU transform buffer and the scene registry's
/// neighbor graph.
///
/// A default `apply` implementation is provided that writes translation-only
/// transforms to `GroupTransformManager` and updates `SceneRegistry.neighborGraph`.
public protocol LayoutManager {
    /// Computes positions and neighbor adjacency for the given entries.
    func layout(entries: [any Positionable]) -> LayoutResult
}

// MARK: - Default Apply

extension LayoutManager {
    /// Writes layout results to the GPU transform buffer and scene registry.
    ///
    /// - Parameters:
    ///   - result: The computed layout result.
    ///   - transforms: The group transform manager for GPU buffer writes.
    ///   - registry: The scene registry to update with the neighbor graph.
    @MainActor
    public func apply(
        result: LayoutResult,
        transforms: GroupTransformManager,
        registry: SceneRegistry
    ) {
        for (id, position) in result.positions {
            guard let entry = registry.entries[id] else { continue }
            transforms.setOffset(entry.groupId, position)
        }
        registry.neighborGraph = result.neighbors
    }
}
