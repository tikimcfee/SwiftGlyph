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
            
            var trashNodes = CodeGridNodes()
            write(
                "This file's just too big right now: \(size)",
                "raw-text-\(UUID().uuidString)",
                .green,
                &trashNodes
            )
            targetGrid.rootNode.setRootMesh()
            return targetGrid
        }
        
        var nodes = CodeGridNodes()
        let id = "raw-text-path-\(UUID().uuidString)"
        write(fullString, id, NSUIColor.white, &nodes)
        targetGrid.tokenCache[id] = nodes
        return targetGrid
    }
    
    public func consumeText(text fullString: String) -> CodeGrid {
        var nodes = CodeGridNodes()
        let id = "raw-text-\(UUID().uuidString)"
        write(fullString, id, NSUIColor.white, &nodes)
        targetGrid.tokenCache[id] = nodes
        return targetGrid
    }
    
    public func write(
        _ string: String,
        _ nodeID: NodeSyntaxID,
        _ color: NSUIColor,
        _ writtenNodeSet: inout CodeGridNodes
    ) {
        for newCharacter in string {
            let glyphKey = GlyphCacheKey(source: newCharacter, color)
            if let node = writer.writeGlyphToState(glyphKey) {
                node.meta.syntaxID = nodeID
                writtenNodeSet.append(node)
                targetCollection.renderer.insert(node)
            } else {
                print("nooooooooooooooooooooo!")
            }
        }
    }
}
