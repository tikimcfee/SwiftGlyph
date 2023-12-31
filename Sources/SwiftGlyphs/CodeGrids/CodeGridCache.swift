//
//  CodeGridConcurrency.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import Foundation
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
    public var tokenCache: CodeGridTokenCache
    
    public init(tokenCache: CodeGridTokenCache = CodeGridTokenCache()) {
        self.tokenCache = tokenCache
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
//            print("[\(requester)] Creating directory: \(key)")
            newGrid = createNewGrid()
        } else {
            newGrid = renderGrid(key) ?? {
                print("[\(requester)] Could not render path \(key)")
                return createNewGrid()
            }()
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
        return CodeGrid(
            rootNode: try! GlyphCollection.makeFromGlobalDefaults(),
            tokenCache: tokenCache
        )
    }
}

extension GridCache: SwiftSyntaxFileLoadable {

    func createGridFromFile(_ url: URL) -> CodeGrid {
        let grid = createNewGrid()
            .withFileName(url.fileName)
            .withSourcePath(url)
        
        if let fileContents = try? String(contentsOf: url, encoding: .utf8) {
            grid.consume(text: fileContents)
        } else {
            print("Could not read contents at: \(url)")
        }
        
        return grid
    }
}

#if canImport(SwiftSyntax)
import SwiftSyntax
public extension GridCache {
    func renderGrid(_ url: URL) -> CodeGrid? {
        if FileBrowser.isSwiftFile(url) {
            guard let sourceFile = loadSourceUrl(url) else { return nil }
            let newGrid = createGridFromSyntax(sourceFile, url)
            return newGrid
        } else {
            return createGridFromFile(url)
        }
    }

    func renderGrid(_ source: String) -> CodeGrid? {
        let sourceFile = parse(source)
        let newGrid = createGridFromSyntax(sourceFile, nil)
        return newGrid
    }

    func createGridFromSyntax(_ syntax: SourceFileSyntax, _ sourceURL: URL?) -> CodeGrid {
        let grid = createNewGrid()
            .consume(rootSyntaxNode: Syntax(syntax))
            .applying {
                guard let url = sourceURL else { return }
                $0.withFileName(url.fileName)
                  .withSourcePath(url)
            }
        
        return grid
    }
}
#endif
