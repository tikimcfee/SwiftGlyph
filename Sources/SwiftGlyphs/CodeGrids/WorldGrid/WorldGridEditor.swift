//
//  WorldGridEditor.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/17/22.
//

import Foundation
import simd
import MetalLink
import BitHandling

var default__VerticalSpacing: VectorFloat = 32.0
var default__HorizontalSpacing: VectorFloat = 32.0
var default__PlaneSpacing: VectorFloat = 128.0
var default__CameraSpacingFromPlaneOnShift: VectorFloat = 64.0

public class WorldGridEditor {
    public enum Strategy {
        case gridRelative
    }
    
    public let snapping = WorldGridSnapping()
    public var layoutStrategy: Strategy = .gridRelative
    
    public var lastFocusedGrid: CodeGrid?
    
    public init() {
        
    }
    
    
    public func applyAllUpdates(
        sizeSortedAdditions: [CodeGrid],
        sizeSortedMissing: [CodeGrid]
    ) {
        print(Array(repeating: "-", count: 64).joined(), "\n")
        
        snapping.clearAll()
        lastFocusedGrid = nil
        
        sizeSortedAdditions.first?.position = .zero
        sizeSortedMissing.first?.position = .zero
        
        let breakPoint = 12
        var gridCounter = 0
        var trailingBreakGrid: CodeGrid? {
            get { snapping.gridReg1 }
            set {
                snapping.gridReg1 = (
                    gridCounter > 0
                    && gridCounter % breakPoint == 0
                ) ? newValue : nil
                gridCounter += 1
            }
        }
        
        func layout(_ grid: CodeGrid) {
            if let _ = trailingBreakGrid {
                transformedByAdding(.inNextRow(grid))
            } else {
                transformedByAdding(.trailingFromLastGrid(grid))
            }
            trailingBreakGrid = grid
        }
        
        guard !sizeSortedAdditions.isEmpty else {
            sizeSortedMissing.forEach {
                layout($0)
            }
            return
        }
        
        // Layout additions first
        sizeSortedAdditions.forEach {
            layout($0)
        }
        
        // Get last grid (should be tallest if sorted) and offset.
        // Following grids will trail.
        if let firstMissing = sizeSortedMissing.first {
            transformedByAdding(.inNextPlane(firstMissing))
        }
        
        sizeSortedMissing.dropFirst().forEach {
            layout($0)
        }
        
    }
    
    @discardableResult
    public func transformedByAdding(_ style: AddStyle) -> WorldGridEditor {
        switch (style, layoutStrategy, lastFocusedGrid) {
        case (_, _, .none):
            style.grid.translated(dX: -30, dY: 30, dZ: -100)
            print("Setting first focused grid: \(style)")
            
        case let (.trailingFromLastGrid(codeGrid), .gridRelative, .some(lastGrid)):
            addTrailing(codeGrid, from: lastGrid)
            
        case let (.inNextRow(codeGrid), .gridRelative, .some(lastGrid)):
            addInNextRow(codeGrid, from: lastGrid)
            
        case let (.inNextPlane(codeGrid), .gridRelative, .some(lastGrid)):
            addInNextPlane(codeGrid, from: lastGrid)
        }
        
        lastFocusedGrid = style.grid
        return self
    }
    
    @discardableResult
    public func remove(_ toRemove: CodeGrid) -> WorldGridEditor {
        if lastFocusedGrid?.id == toRemove.id {
            lastFocusedGrid = nil
        }
        snapping.detachRetaining(toRemove)
        return self
    }
}

private extension WorldGridEditor {
    func addTrailing(
        _ codeGrid: CodeGrid,
        from other: CodeGrid
    ) {
        snapping.connectWithInverses(sourceGrid: other, to: .right(codeGrid))
        
        codeGrid
            .setLeading(other.trailing + default__HorizontalSpacing)
            .setTop(other.top)
            .setFront(other.front)
    }
    
    func addInNextRow(
        _ codeGrid: CodeGrid,
        from other: CodeGrid
    ) {
        snapping.connectWithInverses(sourceGrid: other, to: .down(codeGrid))
        
        var leftMostGrid: CodeGrid?
        let lowestBottomPosition: VectorFloat = getLowestBottomPosition(
            relativeTo: other, moving: .left,
            { leftMostGrid = $0 }
        )
        
        if let leftMostGrid = leftMostGrid {
            codeGrid
                .setLeading(leftMostGrid.leading)
                .setFront(leftMostGrid.front)
                .setTop(lowestBottomPosition - default__VerticalSpacing)
        } else {
            codeGrid
                .setLeading(other.leading)
                .setFront(other.front)
                .setTop(lowestBottomPosition - default__VerticalSpacing)
        }
    }
    
    // functions, huh?
    func getLowestBottomPosition(
        relativeTo other: CodeGrid,
        moving direction: SelfRelativeDirection,
        _ visitor: ((CodeGrid) -> Void)? = nil
    ) -> Float {
        var lowestBottomPosition: VectorFloat = other.bottom
        snapping.iterateOver(other, direction: direction) { _, grid, _ in
            /* do this to have everything connected? */
            /* I can see an 'attempt connection repair' flag for debugging */
//            self.snapping.connectWithInverses(sourceGrid: grid, to: .down(codeGrid))
            lowestBottomPosition = min(lowestBottomPosition, grid.bottom)
            visitor?(grid)
        }
        return lowestBottomPosition
    }
    
    func addInNextPlane(
        _ codeGrid: CodeGrid,
        from other: CodeGrid
    ) {
        snapping.connectWithInverses(sourceGrid: other, to: .forward(codeGrid))
        codeGrid
            .setLeading(0)
            .setTop(0)
            .setFront(other.back - default__PlaneSpacing)
    }
}

// TODO: Does focus belong on editor? Probably. Maybe better state?
public extension WorldGridEditor {
    func shiftFocus(_ shiftDirection: SelfRelativeDirection) {
        guard let lastGrid = lastFocusedGrid else {
            print("No grid to shift focus from; check that at least one transform completed")
            return
        }
        
        let relativeGrids = snapping.gridsRelativeTo(lastGrid, shiftDirection)
        print("Available grids on \(shiftDirection): \(relativeGrids.count)")
        
        guard let firstAvailableGrid = relativeGrids.first else {
            return
        }
        
        lastFocusedGrid = firstAvailableGrid.targetGrid
    }
}

public extension WorldGridEditor {
    enum AddStyle {
        case trailingFromLastGrid(CodeGrid)
        case inNextRow(CodeGrid)
        case inNextPlane(CodeGrid)
//        case topFromLastGrid(CodeGrid)
        
        var grid: CodeGrid {
            switch self {
            case let .trailingFromLastGrid(codeGrid):
                return codeGrid
            case let .inNextRow(codeGrid):
                return codeGrid
            case let .inNextPlane(codeGrid):
                return codeGrid
//            case let .topFromLastGrid(codeGrid):
//                return codeGrid
            }
        }
    }
}

