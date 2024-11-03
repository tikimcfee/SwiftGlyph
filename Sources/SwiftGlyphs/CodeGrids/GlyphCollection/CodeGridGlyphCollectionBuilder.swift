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
    private let sharedTokenCache: CodeGridTokenCache
    
    public init(
        link: MetalLink,
        sharedAtlas atlas: MetalLinkAtlas,
        sharedSemanticMap semanticMap: SemanticInfoMap,
        sharedTokenCache tokenCache: CodeGridTokenCache
    ) throws {
        self.link = link
        self.atlas = atlas
        self.sharedSemanticMap = semanticMap
        self.sharedTokenCache = tokenCache
    }
    
    public func getCollection(
        bufferSize: Int = BackingBufferDefaultSize
    ) -> GlyphCollection {
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
        return grid
    }
    
    public func createGrid(
        around collection: GlyphCollection
    ) -> CodeGrid {
        let grid = CodeGrid(
            rootNode: collection,
            tokenCache: sharedTokenCache
        )
        return grid
    }
    
    public func createConsumerForNewGrid() -> GlyphCollectionSyntaxConsumer {
        GlyphCollectionSyntaxConsumer(targetGrid: createGrid())
    }
}
