//
//  CodeGrid.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/22/21.
//

import Foundation
import SceneKit
import SwiftSyntax
import MetalLink
import MetalLinkHeaders

let kCodeGridContainerName = "CodeGrid"
let kWhitespaceNodeName = "XxX420blazeitspaceXxX"

extension CodeGrid: CustomStringConvertible {
    public var description: String {
"""
CodeGrid(\(id))
""".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public class CodeGrid: Identifiable, Equatable {
    
    public lazy var id = { "\(kCodeGridContainerName)-\(UUID().uuidString)" }()
    
    public var fileName: String = ""
    public var sourcePath: URL?
    
    public var consumedRootSyntaxNodes: [Syntax] = []
    public var semanticInfoMap: SemanticInfoMap = SemanticInfoMap()
    public let semanticInfoBuilder: SemanticInfoBuilder = SemanticInfoBuilder()
    
    public private(set) var rootNode: GlyphCollection
    public private(set) var nameNode: WordNode?
    public let tokenCache: CodeGridTokenCache
    public let gridBackground: BackgroundQuad
    
    public var targetNode: MetalLinkNode { rootNode }
    public var backgroundID: InstanceIDType { gridBackground.constants.pickingId }
    
    public private(set) var childGrids: [CodeGrid] = []
    
    public init(
        rootNode: GlyphCollection,
        tokenCache: CodeGridTokenCache
    ) {
        self.rootNode = rootNode
        self.tokenCache = tokenCache
        self.gridBackground = BackgroundQuad(rootNode.link) // TODO: Link dependency feels lame
        
        setupOnInit()
    }
    
    @discardableResult
    public func applyName() -> CodeGrid {
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
    
    public func setNameNode(_ node: WordNode) {
        if let nameNode {
            targetNode.remove(child: nameNode)
        }
        targetNode.add(child: node)
        self.nameNode = node
    }
    
    public func hideName() {
        nameNode?.hideNode()
    }
    
    public func showName() {
        nameNode?.showNode()
    }
    
    @discardableResult
    public func removeBackground() -> CodeGrid {
        rootNode.remove(child: gridBackground)
        return self
    }
    
    public func updateBackground() {
        let size = targetNode.contentBounds
        gridBackground.size = LFloat2(x: size.width, y: size.height)
        
        gridBackground
            .setLeading(size.leading)
            .setTop(size.top)
            .setFront(back - 1)
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
extension CodeGrid: Hashable {
    public func hash(into hasher: inout Hasher) {
        laztrace(#fileID,#function,hasher)
        hasher.combine(id)
    }
}

// MARK: - Builder-style configuration
// NOTE: - Word of warning
// Grids can describe an entire glyph collection, or represent
// a set of nodes in a collection. Because of this dual job and
// from how the clearinghouse went, Grids owned a reference
// to a collection now, and assume they are the representing object.
// TODO: Add another `GroupMode` to switch between rootNode and collection node updates
extension CodeGrid: Measures {
    public var worldBounds: Bounds {
        targetNode.worldBounds
    }
    
    public var asNode: MetalLinkNode {
        targetNode
    }
    
    public var bounds: Bounds {
        targetNode.bounds
    }
    
    public var boundsCacheKey: MetalLinkNode {
        targetNode
    }
    
    public var sizeBounds: Bounds {
        targetNode.sizeBounds
    }

    public var hasIntrinsicSize: Bool {
        targetNode.hasIntrinsicSize
    }
    
    public var contentBounds: Bounds {
        targetNode.contentBounds
    }
    
    public var nodeId: String {
        targetNode.nodeId
    }
    
    public var position: LFloat3 {
        get {
            targetNode.position
        }
        set {
            targetNode.position = newValue
        }
    }
    
    public var worldPosition: LFloat3 {
        get {
            targetNode.worldPosition
        }
        set {
            targetNode.worldPosition = newValue
        }
    }
    
    public var rotation: LFloat3 {
        get {
            targetNode.rotation
        }
        set {
            targetNode.rotation = newValue
        }
    }
    
    public var lengthX: Float {
        targetNode.lengthX
    }
    
    public var lengthY: Float {
        targetNode.lengthY
    }
    
    public var lengthZ: Float {
        targetNode.lengthZ
    }
    
    public var parent: MetalLinkNode? {
        get {
            targetNode.parent
        }
        set {
            targetNode.parent = newValue
        }
    }
    
    public func convertPosition(_ position: LFloat3, to: MetalLinkNode?) -> LFloat3 {
        targetNode.convertPosition(position, to: to)
    }
    
    public var centerPosition: LFloat3 {
        targetNode.centerPosition
    }
}

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
