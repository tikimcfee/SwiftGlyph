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
    case missingKernelFunction
    case commandQueueError
    case createBufferError
    case commandEncoderFailure
    case pipelineStateFailure
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
    public let commandQueue: MTLCommandQueue
    public let queryRootUrl: URL
    public let language: Language
    public let parser: Parser
    public var cachedQueries = [ColorizerQuery: Query]()
    
    private lazy var pipelineState = CachedValue<MTLComputePipelineState?>(update: {
        do {
            let function = self.link.library.makeFunction(name: "blitColorsIntoConstants")!
            let state = try self.device.makeComputePipelineState(function: function)
            return state
        } catch {
            print(error)
            return nil
        }
    })
    
    public init(
        link: MetalLink,
        queryBaseURL: URL = Bundle.main.resourceURL!
    ) {
        self.link = link
        self.commandQueue = link.device.makeCommandQueue()!
        self.queryRootUrl = queryBaseURL
            .appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle")
            .appendingPathComponent("Contents/Resources/queries/")
        
        self.language = Language(language: tree_sitter_swift())
        self.parser = Parser()
    }
    
    public func runColorizer(
        colorizerQuery: ColorizerQuery,
        on collection: GlyphCollection
    ) throws {
        // Grab the pointer as source of truth
        let (count, pointer) = collection.instancePointerPair
        let atlas = GlobalInstances.defaultAtlas
        
        // Try to rebuild the string (lol)..
        var rebuiltString = Substring(stringLiteral: "")
        for index in (0..<count) {
            let instanceUnicodeData = pointer[index].unicodeHash
            
            if instanceUnicodeData == 10 {
                rebuiltString.append("\n")
                continue
            }
            
            let instanceKey = atlas.builder.cacheRef.unicodeMap[instanceUnicodeData]
            guard let instanceKey else {
                continue
            }
            rebuiltString.append(contentsOf: instanceKey.glyph)
        }
        
        // Make the color buffer, blitit
        let colorBuffer = try execute(
            colorizerQuery: colorizerQuery,
            for: String(rebuiltString)
        )
        try blitColors(
            from: colorBuffer,
            into: collection
        )
    }
    
    public func execute(
        colorizerQuery: ColorizerQuery,
        for loadedText: String
    ) throws -> MTLBuffer {
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
                if case .unknown = matchedType {
                    continue
                }
                
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
    
    public func blitColors(
        from colorBuffer: MTLBuffer,
        into collection: GlyphCollection
    ) throws {
        guard let commandBuffer = commandQueue.makeCommandBuffer()
        else { throw ColorizerError.createBufferError }
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder()
        else { throw ColorizerError.commandEncoderFailure }
        guard let pipelineState = pipelineState.get()
        else { throw ColorizerError.pipelineStateFailure }
        
        commandEncoder.label = collection.nodeId
        commandBuffer.pushDebugGroup("[SG] Color copy \(collection.nodeId)")
        
        commandEncoder.setBuffer(colorBuffer,  offset: 0, index: 0)
        commandEncoder.setBuffer(collection.instanceState.instanceBuffer, offset: 0, index: 1)
        
        let countBuffer = try collection.createInstanceStateCountBuffer()
        commandEncoder.setBuffer(countBuffer, offset: 0, index: 2)
        
        commandEncoder.setComputePipelineState(pipelineState)
        
        // Setup compute groups
        let threadgroups = {
            let bufferElementCount = collection.instanceCount
            let threadgroupWidth = max(pipelineState.threadExecutionWidth - 1, 1)
            let threadgroupsNeeded = (bufferElementCount + threadgroupWidth - 1) / (threadgroupWidth)
            return MTLSize(width: threadgroupsNeeded, height: 1, depth: 1)
        }()
        let threadsPerThreadgroup = MTLSize(width: pipelineState.threadExecutionWidth, height: 1, depth: 1)
        commandEncoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerThreadgroup)

        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        commandBuffer.popDebugGroup()
    }
}
