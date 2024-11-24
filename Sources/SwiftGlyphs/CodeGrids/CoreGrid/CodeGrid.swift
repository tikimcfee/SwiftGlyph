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
    public var nodeId: String {
        "CodeGrid(node)-\(rootNode.nodeId)"
    }
    
    public var fileName: String = ""
    public var sourcePath: URL?
    
    public var consumedRootSyntaxNodes: [Syntax] = []
    public var semanticInfoMap: SemanticInfoMap = SemanticInfoMap()
    public let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
    
    public private(set) var rootNode: GlyphCollection
    
    public private(set) var setName: Bool = false
    public private(set) var nameGrid: CodeGrid?
    public let tokenCache: CodeGridTokenCache
    public var backgroundID: InstanceIDType { wallsBack.constants.pickingId }
    public private(set) var childGrids: [CodeGrid] = []

    // Walls leaking into grids, 's'cool
    weak var weakParentGroup: CodeGridGroup?
    var strongParentGroup: CodeGridGroup?
    var parentGroup: CodeGridGroup? {
        get { strongParentGroup ?? weakParentGroup }
    }
    
    public lazy var wallsTop: BackgroundQuad = makeWall()
    public lazy var wallsLeading: BackgroundQuad = makeWall()
    public lazy var wallsTrailing: BackgroundQuad = makeWall()
    public lazy var wallsBottom: BackgroundQuad = makeWall()
    public lazy var wallsFront: BackgroundQuad = makeWall()
    public lazy var wallsBack: BackgroundQuad = makeWall()
    func makeWall() -> BackgroundQuad {
        let wall = BackgroundQuad(rootNode.link)
        rootNode.add(child: wall)
        wall.constants.pickingId = rootNode.rootConstants.pickingId
        return wall
    }
    // ----------------------------------------------
    
    public init(
        rootNode: GlyphCollection,
        tokenCache: CodeGridTokenCache
    ) {
        self.rootNode = rootNode
        self.tokenCache = tokenCache
        setupOnInit()
    }
    
    private func setupOnInit() {
        rootNode.add(child: wallsBack)
        wallsBack.constants.pickingId = InstanceCounter.shared.nextGridId()
    }
    
    public func applyFlag(_ flag: ConstantsFlags, _ bit: Bool) {
        rootNode.rootConstants.setFlag(flag, bit)
        wallsBack.constants.setFlag(flag, bit)
        nameGrid?.rootNode.rootConstants.setFlag(flag, bit)
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
        
        removeBackground()
    }
    
    @discardableResult
    public func applyName() -> CodeGrid {
//        guard false else { return self }
        guard nameGrid == nil else { return self }
        guard let sourcePath else { return self }
        
        let isDirectory = sourcePath.isDirectory
        let newNameGrid = GlobalInstances.gridStore.builder.createGrid()
        let (_, nodes) = newNameGrid.consume(text: fileName)
        newNameGrid.removeBackground()
        
        let nameColor = isDirectory
            ? LFloat4(0.33, 0.75, 0.45, 1.0)
            : LFloat4(1.00, 0.00, 0.00, 1.0)
        
        let nameScale: Float = isDirectory
            ? 16.0 // directory name size
            : 4.0 // file name size
        
        let namePosition = isDirectory
            ? LFloat3(0.0, 16.0, 0.0)
            : LFloat3(0.0, 4.0, 0.0)
        
        newNameGrid.rootNode.scale = LFloat3(repeating: nameScale)
        for node in nodes {
            nameColor.setAddedColor(on: &node.instanceConstants)
        }
        
        nameGrid = newNameGrid
        addChildGrid(newNameGrid)
        newNameGrid.position = namePosition
        
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
    
    @discardableResult
    public func removeBackground() -> CodeGrid {
        wallsBack.removeFromParent()
        return self
    }
    
    public func updateBackground() {
        let rootSize = rootNode.bounds
        wallsBack.size = LFloat2(
            x: rootSize.width,
            y: rootSize.height
        )
        
        wallsBack
            .setLeading(rootSize.leading)
            .setTop(rootSize.top)
            .setFront(back - 0.39269)
        
        wallsBack.quad.topLeft.position.x  += rootSize.width / 2
        wallsBack.quad.topLeft.position.y  -= rootSize.height / 2
        
        wallsBack.quad.topRight.position.x += rootSize.width / 2
        wallsBack.quad.topRight.position.y -= rootSize.height / 2
        
        wallsBack.quad.bottomLeft.position.x  += rootSize.width / 2
        wallsBack.quad.bottomLeft.position.y  -= rootSize.height / 2
        
        wallsBack.quad.bottomRight.position.x  += rootSize.width / 2
        wallsBack.quad.bottomRight.position.y  -= rootSize.height / 2
    }
    
    @discardableResult
    public func removeFromParent() -> CodeGrid {
        rootNode.removeFromParent()
        
        let toRemove = parentGroup
        weakParentGroup = nil
        strongParentGroup = nil
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
CodeGrid(
    \(id),
    \(sourcePath?.path() ?? fileName),
    in global cache:  \(sourcePath.map { GlobalInstances.gridStore.gridCache.contains($0) } ?? false ),
    is hover tracked: \(GlobalInstances.gridStore.nodeHoverController.contains(self)),
    \(parentGroup.map { "parentGroup: \($0.nodeId)" } ??  "no parent group"),
    \(parent.map { "parent: \($0.nodeId)" } ??  "no parent node"),
    \(!childGrids.isEmpty ? "children: \(childGrids.count)": "no child grids"),
)
""".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
