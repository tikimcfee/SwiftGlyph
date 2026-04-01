//
//  NeighborGraph.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation

/// Directional adjacency for a single scene entry.
/// Used by keyboard navigation commands (`focus.left`, `focus.right`, etc.)
/// to move between grids without re-running layout.
public struct Neighbors: Sendable, Equatable {
    public var left: String?
    public var right: String?
    public var above: String?
    public var below: String?
    public var forward: String?
    public var backward: String?

    public init(
        left: String? = nil,
        right: String? = nil,
        above: String? = nil,
        below: String? = nil,
        forward: String? = nil,
        backward: String? = nil
    ) {
        self.left = left
        self.right = right
        self.above = above
        self.below = below
        self.forward = forward
        self.backward = backward
    }
}

/// Full adjacency structure for the scene.
/// Stored on `SceneRegistry`, updated by layout managers.
/// Keyed by scene entry ID.
public typealias NeighborGraph = [String: Neighbors]
