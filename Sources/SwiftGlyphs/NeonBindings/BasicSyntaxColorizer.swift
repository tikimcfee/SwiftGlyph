//  
//
//  Created on 12/18/23.
//  

import Combine
import MetalKit
import SwiftUI
import MetalLink
import BitHandling
import Foundation

import Neon
import TreeSitterSwift
import SwiftTreeSitter

enum ColorizerError: String, Error {
    case parseDidNotReturnTree
}

public class BasicSyntaxColorizer: MetalLinkReader {
    public enum ColorizerQuery: String, CaseIterable {
        case highlights = "highlights.scm"
        case tags = "tags.scm"
        case locals = "locals.scm"
        
        func url(fromBase: URL) -> URL {
            fromBase.appending(component: rawValue)
        }
    }
    
    public let link: MetalLink
    public let queryRootUrl: URL
    public let language: Language
    public let parser: Parser
    public var cachedQueries = [ColorizerQuery: Query]()
    
    public init(
        link: MetalLink,
        queryBaseURL: URL = Bundle.main.resourceURL!
    ) {
        self.link = link
        self.queryRootUrl = queryBaseURL
            .appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle")
            .appendingPathComponent("Contents/Resources/queries/")
        
        self.language = Language(language: tree_sitter_swift())
        self.parser = Parser()
    }
    
    public func execute(
        colorizerQuery: ColorizerQuery,
        for loadedText: String
    ) async throws -> MTLBuffer {
        // Create the query for the known type
        let treeQuery = try cachedQueries[colorizerQuery] ?? {
            let queryURL = colorizerQuery.url(fromBase: queryRootUrl)
            let newTreeQuery = try language.query(contentsOf: queryURL)
            cachedQueries[colorizerQuery] = newTreeQuery
            return newTreeQuery
        }()
        
        // If the langauge isn't set, try.
        if parser.language == nil {
            try parser.setLanguage(language)
        }
        
        // Read the file (lol... why am I even here...)
        // ... parse it.
        guard
            let tree = parser.parse(loadedText),
            let treeRoot = tree.rootNode
        else { throw ColorizerError.parseDidNotReturnTree }
        
        let cursor = treeQuery.execute(node: treeRoot, in: tree)
        
        // Create output buffer and initialize to .white / (1, 1, 1, 1) / .one
        let outputBuffer = try link.makeBuffer(
            of: LFloat4.self,
            count: loadedText.count
        )
        let outputPointer = outputBuffer.boundPointer(
            as: LFloat4.self, 
            count: loadedText.count
        )
        outputPointer.update(
            repeating: LFloat4.one,
            count: loadedText.count
        )
        
        // Iterate over matches
        for match in cursor {
            for capture in match.captures {
                // We're assumming ranges get overwritten here.
                //
                // Try to parse the syntax type from the components,
                // grab its color, and then write the color out to the entire buffer.
                // This will get copied over into the
                let matchedType = SyntaxType.fromComponents(capture.nameComponents)
                let foregroundColor = matchedType.foregroundColor.vector
                let newPointer = outputPointer.advanced(by: capture.range.lowerBound)
                newPointer.update(
                    repeating: foregroundColor,
                    count: capture.range.length
                )
            }
        }
        
        return outputBuffer
    }
}
