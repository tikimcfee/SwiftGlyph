//
//  CodeGridGroup.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/6/22.
//

import Foundation
import MetalLink
import MetalLinkHeaders
import BitHandling

extension CodeGridGroup: MeasuresDelegating, MetalLinkReader {
    var delegateTarget: any Measures { globalRootGrid }
    var link: MetalLink { globalRootGrid.rootNode.link }
}

class CodeGridGroup {
    let globalRootGrid: CodeGrid
    var childGrids = [CodeGrid]()
    var childGroups = [CodeGridGroup]()
    
    var editor = WorldGridEditor()
    var snapping: WorldGridSnapping { editor.snapping }
    
    let padding: Float = GlobalLiveConfig.Default.codeGridGroupPadding
    let maxRowWidth: Float = GlobalLiveConfig.Default.codeGridGroupMaxRowWidth
    
    init(globalRootGrid: CodeGrid) {
        self.globalRootGrid = globalRootGrid
        
        GlobalInstances.gridStore
            .nodeHoverController
            .attachPickingStream(to: globalRootGrid)
    }
    
    var gridWithGreatestHeight: CodeGrid? {
        get { snapping.gridReg2 }
        set { snapping.gridReg2 = newValue }
    }
    
    var lastRowStartingGrid: CodeGrid? {
        get { snapping.gridReg1 }
        set { snapping.gridReg1 = newValue }
    }
    
    var nextRowStartY: Float {
        gridWithGreatestHeight.map { $0.bottom - 32.0 }
        ?? 0
    }
    
    var gridsPerColumn = 5
    
    func assignAsRootParent() {
        globalRootGrid.strongParentGroup = self
    }
    
    func derez_global() {
        for childGroup in childGroups {
            childGroup.derez_global()
        }
        for childGrid in childGrids {
            childGrid.derez_global()
        }
        
//        childGrids = []
//        childGroups = []
        globalRootGrid.derez_global()
        globalRootGrid.removeFromParent()
        GlobalInstances.gridStore
            .nodeHoverController
            .detachPickingStream(from: globalRootGrid)
//        controller = LinearConstraintController()
    }
    
    func removeChild(_ grid: CodeGrid) {
        let toRemove = childGrids
            .enumerated()
            .reversed()
            .filter { $0.element.id == grid.id }
        
        toRemove.forEach {
            $0.element.derez_global()
            childGrids.remove(at: $0.offset)
        }
        
        if childGrids.isEmpty && childGroups.isEmpty {
            derez_global()
        }
    }
    
    func applyAllConstraints(myDepth: Int) {
        // First, apply constraints recursively to child groups
        for childGroup in childGroups {
            childGroup.applyAllConstraints(myDepth: myDepth + 1)
        }

        // Configuration for layout
        var currentRowWidth: Float = 0.0
        var currentRowY: Float = 0.0
        var maxRowHeightInRow: Float = 0.0

        // Sort grids by volume or any other criteria
        let sortedGrids = childGrids.sorted(by: {
            $0.rootNode.volume < $1.rootNode.volume
        })

        var lastGridInRow: CodeGrid?
        for grid in sortedGrids {
            // Get the grid's bounds (size) using the Measures protocol
            let gridWidth = grid.boundsWidth
            let gridHeight = grid.boundsHeight

            // Check if adding the grid exceeds the maximum row width
            if currentRowWidth + gridWidth + (lastGridInRow != nil ? padding : 0) > maxRowWidth {
                // Start a new row
                currentRowY -= (maxRowHeightInRow + padding)
                currentRowWidth = 0.0
                maxRowHeightInRow = 0.0
                lastGridInRow = nil
            }

            // Position the grid
            if let lastGrid = lastGridInRow {
                // Position to the right of the last grid in the row
                grid.setLeading(lastGrid.trailing + padding)
                grid.setTop(lastGrid.top)
            } else {
                // Start of a new row
                grid.setLeading(0.0)
                grid.setTop(currentRowY)
            }

            // Set the front position (Z-axis), adjust as needed
            grid.setFront(0)

            // Update the current row width and maximum height
            currentRowWidth += gridWidth + (lastGridInRow != nil ? padding : 0)
            maxRowHeightInRow = max(maxRowHeightInRow, gridHeight)

            lastGridInRow = grid
        }

        // After laying out grids, position child groups below the grids
        let sortedGroups = childGroups.sorted(by: {
            $0.asNode.planeAreaXY < $1.asNode.planeAreaXY
        })

        // Starting Y position for groups (below the grids)
        var currentGroupY = currentRowY - (maxRowHeightInRow + padding)
        var currentGroupX: Float = 0.0
        var maxGroupHeightInRow: Float = 0.0
        var lastGroupInRow: CodeGridGroup?

        for group in sortedGroups {
            // Get the group's bounds (size)
            let groupWidth = group.boundsWidth
            let groupHeight = group.boundsHeight

            // Check if adding the group exceeds the maximum row width
            if currentGroupX + groupWidth + (lastGroupInRow != nil ? padding : 0) > maxRowWidth {
                // Start a new row for groups
                currentGroupY -= (maxGroupHeightInRow + padding)
                currentGroupX = 0.0
                maxGroupHeightInRow = 0.0
                lastGroupInRow = nil
            }

            // Position the group
            if let lastGroup = lastGroupInRow {
                // Position to the right of the last group in the row
                group.setLeading(lastGroup.trailing + padding)
                group.setTop(lastGroup.top)
            } else {
                // Start of a new row
                group.setLeading(0.0)
                group.setTop(currentGroupY)
            }

            // Set the front position (Z-axis), adjust as needed
            group.setFront(myDepth.float * GlobalLiveConfig.Default.codeGridGroupDepthPading)

            // Update the current row width and maximum height
            currentGroupX += groupWidth + (lastGroupInRow != nil ? padding : 0)
            maxGroupHeightInRow = max(maxGroupHeightInRow, groupHeight)

            lastGroupInRow = group
        }
    }
    
    func addAllWalls() {
        for childGroup in childGroups {
            childGroup.addAllWalls()
        }
        globalRootGrid.updateWalls()
    }
    
    func addLines(root: MetalLinkNode) {
        for childGroup in childGroups {
            let line = MetalLinkLine(link)
            line.setColor(LFloat4(1.0, 0.0, 0.5, 1.0))
            line.appendSegment(about: worldPosition.translated(dX: -8, dY: 8, dZ: 4))
            line.appendSegment(about: LFloat3(childGroup.worldPosition.x,
                                                         worldPosition.y + 8,
                                                         worldPosition.z + 4))
            line.appendSegment(about: childGroup.worldPosition.translated(dX: -4, dY: 4))
            line.appendSegment(about: childGroup.worldPosition.translated(dX: -2))
            
            root.add(child: line)
            childGroup.addLines(root: root)
        }
        
        for grid in childGrids {
            let line = MetalLinkLine(link)
            line.setColor(LFloat4(0.2, 0.2, 0.8, 1.0))
            line.appendSegment(about: worldPosition.translated(dX: -4, dY: 4))
            line.appendSegment(about: grid.worldPosition.translated(dX: -4, dY: 4))
            line.appendSegment(about: grid.worldPosition.translated(dX: -2))
            
            
            root.add(child: line)
        }
    }
    
    func addChildGrid(_ grid: CodeGrid) {        
        let newGridHeightIsGreater = (gridWithGreatestHeight?.bounds.height ?? 0) < grid.bounds.height
        gridWithGreatestHeight = newGridHeightIsGreater ? grid : gridWithGreatestHeight
        
        grid.weakParentGroup = self
        childGrids.append(grid)
        globalRootGrid.addChildGrid(grid)
    }
    
    func addChildGroup(_ group: CodeGridGroup) {
        childGroups.append(group)
        globalRootGrid.addChildGrid(group.globalRootGrid)
    }
    
    func isSiblingOfGroup(_ otherGroup: CodeGridGroup) -> Bool {
        if let myPath = globalRootGrid.sourcePath,
            let otherPath = otherGroup.globalRootGrid.sourcePath {
            let isSibling = myPath.isSiblingOf(otherPath)
//            if isSibling { print("\(myPath) is sibling of \(otherPath)") }
            return isSibling
        } else {
            print("<!!! you broke it! \(self) ;;;; \(otherGroup)")
            return false
        }
    }
}

// MARK: Simple layout helpers
// Assumes first grid is initial layout target.
// No, I haven't made constraints yet. Ew.

protocol LayoutTarget {
    var layoutNode: MetalLinkNode { get }
    var grids: [MetalLinkNode] { get }
}

extension LayoutTarget {
    var grids: [MetalLinkNode] {
        layoutNode.children.compactMap {
           $0 as? GlyphCollection
        }
    }
}

extension CodeGrid: LayoutTarget {
    var layoutNode: MetalLinkNode { rootNode }
}

extension MetalLinkNode: LayoutTarget {
    var layoutNode: MetalLinkNode { self }
}

struct CircleLayout {
    let radius: Float
    func layout(targets: [LayoutTarget]) {
        let total = targets.count
        for (index, target) in targets.enumerated() {
            let angle = 2 * Float.pi * Float(index) / Float(total)
            let x = radius * cos(angle)
            let y = radius * sin(angle)
            target.layoutNode.setTop(y)
            target.layoutNode.setLeading(x)
        }
    }
}

struct DepthLayout {
    let xGap = 16.float
    let yGap = -64.float
    let zGap = -256.float
    
    func layoutGrids(_ targets: [LayoutTarget]) {
        var lastTarget: LayoutTarget?
        for currentTarget in targets {
            if let lastTarget = lastTarget {
                currentTarget.layoutNode
                    .setTop(lastTarget.layoutNode.top)
                    .setLeading(lastTarget.layoutNode.leading)
                    .setFront(lastTarget.layoutNode.back + zGap)
            }
            lastTarget = currentTarget
        }
    }
    
    func layoutGrids2(
        _ centerX: Float,
        _ centerY: Float,
        _ centerZ: Float,
        _ wordNodes: [WordNode],
        _ parent: CodeGrid
    ) {
        var lastTarget: LayoutTarget?
        
        for currentTarget in wordNodes {
            if let lastTarget {
                let final = lastTarget.layoutNode.position.translated(dZ: zGap)
                currentTarget.position = final
            } else {
                let final = LFloat3(x: centerX, y: centerY, z: centerZ)
                currentTarget.position = final
            }
            lastTarget = currentTarget
        }
    }
}

struct HorizontalLayout {
    let xGap = 16.float
    let yGap = -64.float
    let zGap = 0.float
    
    func layoutGrids(
        _ targets: [LayoutTarget]
    ) {
        var lastTarget: LayoutTarget?
        for currentTarget in targets {
            if let lastTarget = lastTarget {
                currentTarget.layoutNode
                    .setTop(lastTarget.layoutNode.top)
                    .setLeading(lastTarget.layoutNode.trailing + xGap)
                    .setFront(lastTarget.layoutNode.front + zGap)
            }
            lastTarget = currentTarget
        }
    }
}

class VerticalLayout {
    let xGap = 16.float
    let yGap = -64.float
    let zGap = -128.float
    
    func layoutGrids(_ targets: [LayoutTarget]) {
        var lastTarget: LayoutTarget?
        for currentTarget in targets {
            if let lastTarget = lastTarget {
                currentTarget.layoutNode
                    .setTop(lastTarget.layoutNode.bottom + yGap)
                    .setLeading(lastTarget.layoutNode.leading)
                    .setFront(lastTarget.layoutNode.front)
            }
            lastTarget = currentTarget
        }
    }
}
