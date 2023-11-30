//
//  GlyphCollection+Consume.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import SwiftSyntax
import MetalLink
import MetalLinkHeaders
import MetalKit
import BitHandling

public struct GlyphCollectionSyntaxConsumer: SwiftSyntaxFileLoadable {
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
        guard let fileSource = loadSourceUrl(url) else {
            return consumeText(textPath: url)
        }
        let size = fileSource.root.allText.count + 512
        
        guard size < 1_000_000 else {
            print("Yo dude that's just like too many letters and stuff: \(url)")
            
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
        
        try? targetGrid
            .rootNode
            .instanceState
            .constants
            .expandBuffer(nextSize: size, force: true)
        
        print("starting consume: \(url.lastPathComponent)")
        consume(rootSyntaxNode: Syntax(fileSource))
        print("completed consume: \(url.lastPathComponent)")
        
        return targetGrid
    }
    
    public func consumeText(textPath: URL) -> CodeGrid {
        guard let fullString = try? String(contentsOf: textPath) else {
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
    
    // --> cmd+f 'slow-stuff'
    public func consume(rootSyntaxNode: Syntax) {
        FlatteningVisitor(
            target: targetGrid.semanticInfoMap,
            builder: targetGrid.semanticInfoBuilder
        ).walkRecursiveFromSyntax(rootSyntaxNode)
        
        for token in rootSyntaxNode.tokens(viewMode: .all) {
            consumeSyntaxToken(token)
        }
        
        targetGrid.consumedRootSyntaxNodes.append(rootSyntaxNode)
        targetGrid.updateBackground()
        targetCollection.setRootMesh()
    }
    
    private func consumeSyntaxToken(_ token: TokenSyntax) {
        // Setup identifiers and build out token text
        let tokenId = token.id
        let tokenIdNodeName = tokenId.stringIdentifier
        let triviaColor = CodeGridColors.trivia
        let tokenColor = token.defaultColor
        
        // Combine all nodes into same set, colorize trivia differently
        var allCharacterNodes = CodeGridNodes()
        let leadingTrivia = token.leadingTrivia.stringified
        let tokenText = token.text
        let trailingTrivia = token.trailingTrivia.stringified
        
        write(leadingTrivia, tokenIdNodeName, triviaColor, &allCharacterNodes)
        write(tokenText, tokenIdNodeName, tokenColor, &allCharacterNodes)
        write(trailingTrivia, tokenIdNodeName, triviaColor, &allCharacterNodes)
        
        targetGrid.tokenCache[tokenIdNodeName] = allCharacterNodes
        targetGrid.semanticInfoMap.insertNodeInfo(tokenIdNodeName, tokenId)
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
