//
//  GlyphCollection+Consume.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import MetalLink
import MetalLinkHeaders
import MetalKit
import BitHandling

public struct GlyphCollectionSyntaxConsumer {
    public let targetGrid: CodeGrid
    public let targetCollection: GlyphCollection
    public var writer: GlyphCollectionWriter
    
    public init(targetGrid: CodeGrid) {
        self.targetGrid = targetGrid
        self.targetCollection = targetGrid.rootNode
        self.writer = GlyphCollectionWriter(target: targetCollection)
    }
    
    @discardableResult
    public func consume(url: URL) -> CodeGrid {
        return consumeText(textPath: url)
    }
    
    public func consumeText(textPath: URL) -> CodeGrid {
        guard let fullString = try? String(contentsOf: textPath) else {
            return targetGrid
        }
        let size = fullString.count + 512
        
        guard size < 1_000_000 else {
            print("Yo dude that's just like too many letters and stuff: \(textPath)")
            
            var trashNodes = [GlyphNode]()
            write(
                "This file's just too big right now: \(size)",
                "raw-text-\(UUID().uuidString)",
                &trashNodes
            )
            targetGrid.rootNode.setRootMesh()
            return targetGrid
        }
        
        var nodes = [GlyphNode]()
        let id = "raw-text-path-\(UUID().uuidString)"
        write(fullString, id, &nodes)
        targetGrid.tokenCache[id] = nodes
        return targetGrid
    }
    
    public func consumeText(text fullString: String) -> CodeGrid {
        var nodes = [GlyphNode]()
        let id = "raw-text-\(UUID().uuidString)"
        write(fullString, id, &nodes)
        targetGrid.tokenCache[id] = nodes
        return targetGrid
    }
    
    public func write(
        _ string: String,
        _ nodeID: NodeSyntaxID,
        _ writtenNodeSet: inout [GlyphNode]
    ) {
        for newCharacter in string {
            if let node = writer.writeGlyphToState(newCharacter) {
                node.meta.syntaxID = nodeID
                writtenNodeSet.append(node)
                targetCollection.renderer.insert(node)
            } else {
                print("nooooooooooooooooooooo!")
            }
        }
    }
}
