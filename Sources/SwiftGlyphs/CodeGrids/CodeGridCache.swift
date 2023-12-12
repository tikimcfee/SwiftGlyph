//
//  CodeGridConcurrency.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import SwiftUI
import BitHandling
import MetalLink

// See MetalLink for reasons
public typealias GlyphCollection = MetalLinkGlyphCollection

public extension GlyphCollection {
    static func makeFromGlobalDefaults() throws -> GlyphCollection {
        try GlyphCollection(
            link: GlobalInstances.defaultLink,
            linkAtlas: GlobalInstances.defaultAtlas
        )
    }
}

public class GridCache {
    public typealias CacheValue = CodeGrid
    public let cachedGrids = ConcurrentDictionary<CodeGrid.ID, CacheValue>()
    public var cachedFiles = ConcurrentDictionary<URL, CodeGrid.ID>()
    
    public let builder: CodeGridGlyphCollectionBuilder
    
    public init(
        builder: CodeGridGlyphCollectionBuilder
    ) {
        self.builder = builder
    }
    
    public func insertGrid(_ key: CodeGrid) {
        cachedGrids[key.id] = key
        if let source = key.sourcePath {
            cachedFiles[source] = key.id
        }
    }
    
    public func setCache(_ key: URL, _ requester: String = #function) -> CodeGrid {
        let newGrid: CodeGrid
        if key.isDirectory {
            print("[\(requester)] SetCache : Creating directory: \(key)")
            newGrid = createNewGrid()
        } else {
            print("[\(requester)] SetCache : Creating file: \(key)")
            newGrid = builder
                .createConsumerForNewGrid()
                .consume(url: key)
                .withFileName(key.fileName)
                .withSourcePath(key)
        }
        
        cachedGrids[newGrid.id] = newGrid
        cachedFiles[key] = newGrid.id
        return newGrid
    }
    
    public func getOrCache(_ key: URL) -> CodeGrid {
        if let gridId = cachedFiles[key],
           let grid = cachedGrids[gridId] {
            return grid
        }
        
        return setCache(key)
    }
    
    public func get(_ key: URL) -> CacheValue? {
        guard let cachedId = cachedFiles[key] else { return nil }
        return cachedGrids[cachedId]
    }
    
    public func createNewGrid() -> CodeGrid {
        return builder.createGrid()
    }
}
