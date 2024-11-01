//
//  CodeGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import MetalLink
import MetalLinkHeaders

public class CodeGrid: Identifiable, Equatable {
    
    public var uuid = UUID()
    public var id: String {
        "CodeGrid-\(uuid.uuidString)"
    }
    
    public var fileName: String = ""
    public var sourcePath: URL?
    
    public var consumedRootSyntaxNodes: [Syntax] = []
    public var semanticInfoMap: SemanticInfoMap = SemanticInfoMap()
    public let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
    
    public private(set) var rootNode: GlyphCollection
    
    public private(set) var nameNode: WordNode?
    public let tokenCache: CodeGridTokenCache
    public let gridBackground: BackgroundQuad
    public var backgroundID: InstanceIDType { gridBackground.constants.pickingId }
    public private(set) var childGrids: [CodeGrid] = []

    // Walls leaking into grids, 's'cool
    weak var parentGroup: CodeGridGroup?
    
    private lazy var groupWalls = {
        var walls = [
            BackgroundQuad(rootNode.link), // top
            BackgroundQuad(rootNode.link), // leading
            BackgroundQuad(rootNode.link), // trailing
            BackgroundQuad(rootNode.link), // bottom
            BackgroundQuad(rootNode.link)  // front
        ]
        walls.forEach {
            rootNode.add(child: $0)
            $0.constants.pickingId = gridBackground.constants.pickingId
        }
        walls.append(gridBackground) // <--   default is back wall
        return walls
    }()
    public var wallsTop: BackgroundQuad { groupWalls[0] }
    public var wallsLeading: BackgroundQuad { groupWalls[1] }
    public var wallsTrailing: BackgroundQuad { groupWalls[2] }
    public var wallsBottom: BackgroundQuad { groupWalls[3] }
    public var wallsFront: BackgroundQuad { groupWalls[4] }
    public var wallsBack: BackgroundQuad { groupWalls[5] }
    // ----------------------------------------------
    
    public init(
        rootNode: GlyphCollection,
        tokenCache: CodeGridTokenCache
    ) {
        self.rootNode = rootNode
        self.tokenCache = tokenCache
        self.gridBackground = BackgroundQuad(rootNode.link)
        
        setupOnInit()
    }
    
    public func derez_global() {
        derez(
            cache: GlobalInstances.gridStore.gridCache,
            controller: GlobalInstances.gridStore.nodeHoverController,
            editor: GlobalInstances.gridStore.editor
        )
    }
    
    public func derez(
        cache: GridCache,
        controller: MetalLinkHoverController,
        editor: WorldGridEditor
    ) {
        let toDerez = childGrids
        childGrids = []
        
        for child in toDerez {
            child.derez(
                cache: cache,
                controller: controller,
                editor: editor
            )
        }
        
        removeFromParent()
        cache.removeGrid(self)
        controller.detachPickingStream(from: self)
        editor.remove(self)
//        rootNode.clearChildren()
        removeBackground()
    }
    
    @discardableResult
    public func applyName() -> CodeGrid {
//        guard false else { return self }
        
        guard nameNode == nil else { return self }
        guard let sourcePath else { return self }
        let isDirectory = sourcePath.isDirectory
        
        let (_, nodes) = consume(text: fileName)
        let nameNode = WordNode(
            sourceWord: fileName,
            glyphs: nodes,
            parentGrid: self
        )
        
        let nameColor = isDirectory
            ? LFloat4(0.33, 0.75, 0.45, 1.0)
            : LFloat4(1.00, 0.00, 0.00, 1.0)
        
        let nameScale: Float = isDirectory
            ? 16.0 // directory name size
            : 4.0 // file name size
        
        let namePosition = isDirectory
            ? LFloat3(0.0, 16.0, 0.0)
            : LFloat3(0.0, 4.0, 0.0)
        
        
        nameNode.position = namePosition
        nameNode.scale = LFloat3(repeating: nameScale)
        
        nameNode.glyphs.forEach {
            $0.instanceConstants?.addedColor = nameColor
        }
        
        setNameNode(nameNode)
        return self
    }
    
    @discardableResult
    public func updateWalls() -> CodeGrid {
        let childBounds = childGrids
            .reduce(into: Bounds.forBaseComputing) {
                $0.union(with: $1.sizeBounds)
            }
        
        wallsLeading.applyLeading(childBounds)
        wallsLeading.position.x -= 4
        wallsLeading.setColor(LFloat4(0.2, 0.1, 0.1, 1.0))

        wallsTrailing.applyTrailing(childBounds)
        wallsTrailing.position.x += 4
        wallsTrailing.setColor(LFloat4(0.1, 0.1, 0.1, 1.0))
        
//        childBounds.applyTop(wallsTop)
//        wallsTop.position -= 4
//        wallsTop.setColor(LFloat4(0.1, 0.3, 0.3, 1.0))
        
        wallsBottom.applyBottom(childBounds)
        wallsBottom.position.y -= 4
        wallsBottom.setColor(LFloat4(0.0, 0.1, 0.1, 1.0))
        
        wallsBack.applyBack(childBounds)
        wallsBack.position.z -= 4
        wallsBack.setColor(LFloat4(0.1, 0.2, 0.2, 1.0))
        
        return self
    }
    
    public func setNameNode(_ node: WordNode) {
        if let nameNode {
            print("-- Resetting name on \(String(describing: sourcePath))")
            rootNode.remove(child: nameNode)
            nameNode.parentGrid = nil
        }
        rootNode.add(child: node)
        self.nameNode = node
        node.parentGrid = self
    }
    
    @discardableResult
    public func removeBackground() -> CodeGrid {
        rootNode.remove(child: gridBackground)
        return self
    }
    
    public func updateBackground() {
        let size = rootNode.bounds
        gridBackground.size = LFloat2(x: size.width, y: size.height)
        
        gridBackground
            .setLeading(size.leading)
            .setTop(size.top)
            .setFront(back - 0.39269)
    }
    
    @discardableResult
    public func removeFromParent() -> CodeGrid {
        rootNode.removeFromParent()
        
        let toRemove = parentGroup
        parentGroup = nil
        toRemove?.removeChild(self)
        
        return self
    }
    
    public func addChildGrid(_ other: CodeGrid) {
        childGrids.append(other)
        rootNode.add(child: other.rootNode)
    }
    
    public func removeChildGrid(_ other: CodeGrid) {
        childGrids.removeAll(where: { $0.id == other.id })
        rootNode.remove(child: other.rootNode)
    }
        
    private func setupOnInit() {
        rootNode.add(child: gridBackground)
        gridBackground.constants.pickingId = InstanceCounter.shared.nextGridId()
    }
    
    public static func == (_ left: CodeGrid, _ right: CodeGrid) -> Bool {
        laztrace(#fileID,#function,left,right)
        return left.id == right.id
    }
}

// MARK: - Hashing
extension CodeGrid {
    func copyDisplayState(from other: CodeGrid) {
        self.uuid = other.uuid
        self.position = other.position
        self.rotation = other.rotation
        self.sourcePath = other.sourcePath
        self.fileName = other.fileName
        
        self.applyName()
        self.updateBackground()
    }
}

extension CodeGrid: Hashable {
    public func hash(into hasher: inout Hasher) {
        laztrace(#fileID,#function,hasher)
        hasher.combine(id)
    }
}

// MARK: - Builder-style configuration

public extension CodeGrid {
    @discardableResult
    func zeroedPosition() -> CodeGrid {
        position = .zero
        return self
    }
    
    @discardableResult
    func translated(
        dX: Float = 0,
        dY: Float = 0,
        dZ: Float = 0
    ) -> CodeGrid {
        laztrace(#fileID,#function,dX,dY,dZ)
        position = position.translated(dX: dX, dY: dY, dZ: dZ)
        return self
    }
    
    @discardableResult
    func translated(
        deltaPosition: LFloat3 = .zero
    ) -> CodeGrid {
        laztrace(#fileID,#function,deltaPosition)
        position += deltaPosition
        return self
    }
    
    @discardableResult
    func applying(_ action: (CodeGrid) -> Void) -> CodeGrid {
        laztrace(#fileID,#function)
        action(self)
        return self
    }
    
    @discardableResult
    func withFileName(_ fileName: String) -> Self {
        self.fileName = fileName
        return self
    }
    
    @discardableResult
    func withSourcePath(_ filePath: URL) -> Self {
        self.sourcePath = filePath
        return self
    }
}

extension CodeGrid: MeasuresDelegating {
    public var delegateTarget: any Measures { rootNode }
}

extension CodeGrid: CustomStringConvertible {
    public var description: String {
"""
CodeGrid(\(id))
""".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
