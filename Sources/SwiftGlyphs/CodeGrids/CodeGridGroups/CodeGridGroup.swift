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
    
    func applyAllConstraints() {
        for childGroup in childGroups {
            childGroup.applyAllConstraints()
        }

        let sortedGrids = childGrids.sorted(by: {
            $0.rootNode.planeAreaXY < $1.rootNode.planeAreaXY
        })
        var lastGrid: CodeGrid?
        for (_, grid) in sortedGrids.enumerated() {
            if let lastGrid {
                grid.setTop(lastGrid.top)
                grid.setFront(lastGrid.back - 128)
                grid.setLeading(lastGrid.leading)
            }
            lastGrid = grid
        }
        
        let sortedGroups = childGroups.sorted(by: {
            $0.asNode.planeAreaXY > $1.asNode.planeAreaXY
        })
        var lastGroup: CodeGridGroup?
        for childGroup in sortedGroups {
            childGroup.setTop(nextRowStartY - 32)
            if let lastGroup {
                childGroup.setLeading(lastGroup.trailing + 32)
                childGroup.setFront(lastGroup.front)
            }
            lastGroup = childGroup
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
