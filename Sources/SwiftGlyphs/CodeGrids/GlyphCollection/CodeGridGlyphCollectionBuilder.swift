//
//  CodeGridGlyphCollectionBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import simd
import Foundation
import MetalLink
import MetalLinkHeaders

public class CodeGridGlyphCollectionBuilder {
    let link: MetalLink
    let atlas: MetalLinkAtlas
    let sharedSemanticMap: SemanticInfoMap
    let sharedTokenCache: CodeGridTokenCache
    let sharedGridCache: GridCache
    
    public init(
        link: MetalLink,
        sharedSemanticMap semanticMap: SemanticInfoMap,
        sharedTokenCache tokenCache: CodeGridTokenCache,
        sharedGridCache gridCache: GridCache
    ) throws {
        self.link = link
        self.atlas = GlobalInstances.defaultAtlas
        self.sharedSemanticMap = semanticMap
        self.sharedTokenCache = tokenCache
        self.sharedGridCache = gridCache
    }
    
    public func getCollection(bufferSize: Int = BackingBufferDefaultSize) -> GlyphCollection {
        return try! GlyphCollection(
            link: link,
            linkAtlas: atlas,
            bufferSize: bufferSize
        )
    }
    
    public func createGrid(
        bufferSize: Int = BackingBufferDefaultSize
    ) -> CodeGrid {
        let grid = CodeGrid(
            rootNode: getCollection(bufferSize: bufferSize),
            tokenCache: sharedTokenCache
        )
        sharedGridCache.cachedGrids[grid.id] = grid
        
        return grid
    }
    
    public func createConsumerForNewGrid() -> GlyphCollectionSyntaxConsumer {
        GlyphCollectionSyntaxConsumer(targetGrid: createGrid())
    }
}
