//
//  GridLayoutManager.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 2026-03-31.
//

import Foundation
import simd
import MetalLink

/// Row-column-plane grid layout strategy.
///
/// Positions entries in a 2D grid (rows and columns) with optional
/// depth planes. Ported from the JS GridLayoutManager.
///
/// Configuration:
/// - `columnsPerRow`: How many entries per row before wrapping.
/// - `horizontalSpacing`: Gap between columns.
/// - `verticalSpacing`: Gap between rows.
/// - `planeSpacing`: Gap between depth planes (for 3D grid layout).
///
/// Neighbor adjacency is computed during layout: entries know their
/// left/right/above/below neighbors based on grid position.
public struct GridLayoutManager: LayoutManager {

    // MARK: - Configuration

    public var columnsPerRow: Int
    public var horizontalSpacing: Float
    public var verticalSpacing: Float
    public var planeSpacing: Float

    public init(
        columnsPerRow: Int = 6,
        horizontalSpacing: Float = 32.0,
        verticalSpacing: Float = 32.0,
        planeSpacing: Float = 128.0
    ) {
        self.columnsPerRow = columnsPerRow
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.planeSpacing = planeSpacing
    }

    // MARK: - LayoutManager

    public func layout(entries: [any Positionable]) -> LayoutResult {
        guard !entries.isEmpty else {
            return LayoutResult(positions: [:], neighbors: [:])
        }

        var positions: [String: LFloat3] = [:]
        var neighbors: NeighborGraph = [:]

        // Track row heights for proper vertical stacking.
        // Each row's height is the maximum entry height in that row.
        var currentX: Float = 0
        var currentY: Float = 0
        var rowMaxHeight: Float = 0
        var column = 0

        // Store row/column indices for neighbor computation
        struct GridCell {
            let id: String
            let row: Int
            let col: Int
        }
        var cells: [GridCell] = []
        var currentRow = 0

        for entry in entries {
            if column >= columnsPerRow {
                // Wrap to next row
                column = 0
                currentRow += 1
                currentX = 0
                currentY -= (rowMaxHeight + verticalSpacing)
                rowMaxHeight = 0
            }

            positions[entry.id] = LFloat3(currentX, currentY, 0)
            cells.append(GridCell(id: entry.id, row: currentRow, col: column))

            currentX += entry.bounds.x + horizontalSpacing
            rowMaxHeight = max(rowMaxHeight, entry.bounds.y)
            column += 1
        }

        // Build neighbor graph from grid cells
        // Create a lookup by (row, col)
        var cellLookup: [Int: [Int: String]] = [:]  // [row: [col: id]]
        for cell in cells {
            cellLookup[cell.row, default: [:]][cell.col] = cell.id
        }

        for cell in cells {
            var n = Neighbors()
            n.left = cellLookup[cell.row]?[cell.col - 1]
            n.right = cellLookup[cell.row]?[cell.col + 1]
            n.above = cellLookup[cell.row - 1]?[cell.col]
            n.below = cellLookup[cell.row + 1]?[cell.col]
            neighbors[cell.id] = n
        }

        return LayoutResult(positions: positions, neighbors: neighbors)
    }
}
