//
//  HierarchicalLayoutManager.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import simd
import MetalLink

/// Directory-tree-aware hierarchical layout strategy.
///
/// Ported from the JS HierarchicalLayoutManager. Operates in four phases:
///   1. **Build tree** -- Infers parent-child relationships from entry IDs
///      (treating "/" as a path separator).
///   2. **Compute bounds bottom-up** -- Leaf entries use their own bounds.
///      Interior nodes accumulate child bounds with padding.
///   3. **Position top-down** -- Starting from the root, children are placed
///      in rows within their parent's allocated space.
///   4. **Apply** -- Flattened positions are written to GroupTransformManager
///      and the neighbor graph is updated.
///
/// Neighbor adjacency uses sibling order: left/right neighbors are the
/// previous/next sibling in the same directory.
public struct HierarchicalLayoutManager: LayoutManager {

    // MARK: - Configuration

    public var horizontalPadding: Float
    public var verticalPadding: Float
    public var depthSpacing: Float
    public var maxRowWidth: Float

    public init(
        horizontalPadding: Float = 24.0,
        verticalPadding: Float = 24.0,
        depthSpacing: Float = 64.0,
        maxRowWidth: Float = 1200.0
    ) {
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.depthSpacing = depthSpacing
        self.maxRowWidth = maxRowWidth
    }

    // MARK: - LayoutManager

    public func layout(entries: [any Positionable]) -> LayoutResult {
        guard !entries.isEmpty else {
            return LayoutResult(positions: [:], neighbors: [:])
        }

        // Phase 1: Build tree from entry IDs
        let root = buildTree(from: entries)

        // Phase 2: Compute bounds bottom-up
        computeBounds(node: root)

        // Phase 3: Position top-down
        var positions: [String: LFloat3] = [:]
        positionNode(root, at: LFloat3.zero, depth: 0, positions: &positions)

        // Phase 4: Build neighbor graph from sibling order
        var neighbors: NeighborGraph = [:]
        buildNeighbors(node: root, neighbors: &neighbors)

        return LayoutResult(positions: positions, neighbors: neighbors)
    }

    // MARK: - Phase 1: Build Tree

    private func buildTree(from entries: [any Positionable]) -> TreeNode {
        let root = TreeNode(id: "__root__", entry: nil)
        var entryMap: [String: any Positionable] = [:]
        for entry in entries {
            entryMap[entry.id] = entry
        }

        for entry in entries {
            let components = entry.id.split(separator: "/").map(String.init)
            var current = root

            for (i, component) in components.enumerated() {
                let pathSoFar = components.prefix(i + 1).joined(separator: "/")

                if let existing = current.childMap[pathSoFar] {
                    current = existing
                } else {
                    let isLeaf = (i == components.count - 1)
                    let node = TreeNode(
                        id: pathSoFar,
                        entry: isLeaf ? entryMap[entry.id] : nil
                    )
                    node.name = component
                    current.children.append(node)
                    current.childMap[pathSoFar] = node
                    current = node
                }
            }
        }

        // If root has exactly one child, skip the synthetic root
        if root.children.count == 1 {
            return root.children[0]
        }

        return root
    }

    // MARK: - Phase 2: Compute Bounds Bottom-Up

    private func computeBounds(node: TreeNode) {
        if node.children.isEmpty {
            // Leaf: use entry bounds or a default
            if let entry = node.entry {
                node.computedBounds = LFloat3(
                    entry.bounds.x,
                    entry.bounds.y,
                    entry.bounds.z
                )
            } else {
                node.computedBounds = LFloat3(80, 40, 1)
            }
            return
        }

        for child in node.children {
            computeBounds(node: child)
        }

        // Pack children into rows to compute total bounds
        var totalWidth: Float = 0
        var totalHeight: Float = 0
        var rowWidth: Float = 0
        var rowHeight: Float = 0

        for child in node.children {
            let childWidth = child.computedBounds.x + horizontalPadding
            let childHeight = child.computedBounds.y

            if rowWidth + childWidth > maxRowWidth && rowWidth > 0 {
                totalWidth = max(totalWidth, rowWidth)
                totalHeight += rowHeight + verticalPadding
                rowWidth = 0
                rowHeight = 0
            }

            rowWidth += childWidth
            rowHeight = max(rowHeight, childHeight)
        }

        totalWidth = max(totalWidth, rowWidth)
        totalHeight += rowHeight

        node.computedBounds = LFloat3(
            totalWidth + horizontalPadding,
            totalHeight + verticalPadding,
            1
        )
    }

    // MARK: - Phase 3: Position Top-Down

    private func positionNode(
        _ node: TreeNode,
        at origin: LFloat3,
        depth: Int,
        positions: inout [String: LFloat3]
    ) {
        let depthOffset = Float(depth) * depthSpacing

        // Position this node's entry (if it is a leaf)
        if node.entry != nil {
            positions[node.entry!.id] = LFloat3(origin.x, origin.y, -depthOffset)
        }

        // Position children within this node's space
        var cursorX = origin.x
        var cursorY = origin.y
        var rowHeight: Float = 0

        for child in node.children {
            let childWidth = child.computedBounds.x + horizontalPadding

            if cursorX - origin.x + childWidth > maxRowWidth && cursorX > origin.x {
                cursorX = origin.x
                cursorY -= (rowHeight + verticalPadding)
                rowHeight = 0
            }

            positionNode(
                child,
                at: LFloat3(cursorX, cursorY, 0),
                depth: depth + 1,
                positions: &positions
            )

            cursorX += childWidth
            rowHeight = max(rowHeight, child.computedBounds.y)
        }
    }

    // MARK: - Phase 4: Build Neighbors

    private func buildNeighbors(node: TreeNode, neighbors: inout NeighborGraph) {
        let siblings = node.children

        for (i, child) in siblings.enumerated() {
            if child.entry != nil {
                var n = neighbors[child.entry!.id] ?? Neighbors()

                if i > 0, let prevEntry = siblings[i - 1].leafEntry {
                    n.left = prevEntry.id
                }
                if i < siblings.count - 1, let nextEntry = siblings[i + 1].leafEntry {
                    n.right = nextEntry.id
                }
                // Parent is "above", first child is "below"
                if let parentEntry = node.entry {
                    n.above = parentEntry.id
                }
                if let firstChildEntry = child.children.first?.leafEntry {
                    n.below = firstChildEntry.id
                }

                neighbors[child.entry!.id] = n
            }

            buildNeighbors(node: child, neighbors: &neighbors)
        }
    }
}

// MARK: - Tree Node (Internal)

/// Internal tree structure used during hierarchical layout computation.
/// Not exposed outside this file.
private final class TreeNode {
    let id: String
    var name: String
    let entry: (any Positionable)?
    var children: [TreeNode] = []
    var childMap: [String: TreeNode] = [:]
    var computedBounds: LFloat3 = .zero

    init(id: String, entry: (any Positionable)?) {
        self.id = id
        self.name = id
        self.entry = entry
    }

    /// Returns this node's entry if it is a leaf, or the first descendant's entry.
    var leafEntry: (any Positionable)? {
        if let entry { return entry }
        for child in children {
            if let found = child.leafEntry { return found }
        }
        return nil
    }
}
