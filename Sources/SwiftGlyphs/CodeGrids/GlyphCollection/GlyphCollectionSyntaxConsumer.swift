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

struct GlyphCollectionSyntaxConsumer: SwiftSyntaxFileLoadable {
    let targetGrid: CodeGrid
    let targetCollection: GlyphCollection
    var writer: GlyphCollectionWriter
    
    private static let __TEST_ASYNC__ = false
    
    init(targetGrid: CodeGrid) {
        self.targetGrid = targetGrid
        self.targetCollection = targetGrid.rootNode
        self.writer = GlyphCollectionWriter(target: targetCollection)
    }
    
    func ___BRING_THE_METAL__(_ fileURL: URL) {
        // Read the file into a Data object
        let data: NSData
        do {
            data = try NSData(contentsOf: fileURL, options: .alwaysMapped)
        } catch {
            data = NSData()
            print("Failed to read \(fileURL), returning empty data")
        }
        
        // Setup Metal
        let device = GlobalInstances.defaultLink.device
//        let commandQueue = GlobalInstances.defaultLink.commandQueue
        
        // Create a Metal buffer from the Data object
        guard let metalBuffer = device.makeBuffer(
            bytes: data.bytes,
            length: data.count,
            options: []
        ) else {
            fatalError("Unable to create Metal buffer")
        }
        
        print("have a new buffer I thinK: ", metalBuffer.length)
//        runComputeKernel(on: metalBuffer)
        runComputeKernel32(on: metalBuffer)
    }

    func runComputeKernel(on metalBuffer: MTLBuffer) {
        let defaultLibrary = GlobalInstances.defaultLink.defaultLibrary
        let device = GlobalInstances.defaultLink.device
        let commandQueue = GlobalInstances.defaultLink.commandQueue
        
        guard let kernelFunction = defaultLibrary.makeFunction(name: "characterMappingKernel"),
              let computePipelineState = try? device.makeComputePipelineState(function: kernelFunction)
        else {
            fatalError("Unable to create compute pipeline state")
        }

        // Create a command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            fatalError("Unable to create command buffer or encoder")
        }

        // Create an output buffer
        
        let outputBuffer = device.makeBuffer(
            length: metalBuffer.length,
            options: []
        )

        // Set the compute kernel's parameters
        computeCommandEncoder.setBuffer(metalBuffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        computeCommandEncoder.setComputePipelineState(computePipelineState)

        // Calculate the number of threads and threadgroups
        let threadGroupSize = MTLSize(
            width: computePipelineState.threadExecutionWidth,
            height: 1,
            depth: 1
        )
        
        let threadGroupsWidth = (metalBuffer.length + threadGroupSize.width - 1) / threadGroupSize.width
        let threadGroups = MTLSize(
            width: threadGroupsWidth,
            height: 1,
            depth: 1
        )

        // Dispatch the compute kernel
        computeCommandEncoder.dispatchThreadgroups(
            threadGroups,
            threadsPerThreadgroup: threadGroupSize
        )

        // Finalize encoding and commit the command buffer
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Here you can read back the data from 'outputBuffer' if needed
        print(outputBuffer)
        // HA... HAHAAA.... HAAAA HAHAHAHAHA!
//        po String.init(cString: outputBuffer!.contents().bindMemory(to: UInt8.self, capacity: 1163))
    }
    
    func runComputeKernel32(on metalBuffer: MTLBuffer) -> String? {
        let defaultLibrary = GlobalInstances.defaultLink.defaultLibrary
        let device = GlobalInstances.defaultLink.device
        let commandQueue = GlobalInstances.defaultLink.commandQueue
        
        // Use the new kernel function name
        guard let kernelFunction = defaultLibrary.makeFunction(name: "utf8ToUtf32Kernel"),
              let computePipelineState = try? device.makeComputePipelineState(function: kernelFunction)
        else {
            print("Unable to create compute pipeline state")
            return nil
        }

        // Create a command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeCommandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("Unable to create command buffer or encoder")
            return nil
        }

        // Create an output buffer matching the GlyphMapKernelOut structure
        let outputBufferSize = metalBuffer.length * MemoryLayout<GlyphMapKernelOut>.stride
        guard let outputBuffer = device.makeBuffer(length: outputBufferSize, options: []) else {
            print("Unable to create output buffer")
            return nil
        }

        // Set the compute kernel's parameters
        computeCommandEncoder.setBuffer(metalBuffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(outputBuffer, offset: 0, index: 1)
        
        // Pass the size of the UTF-8 buffer as a constant
        var utf8BufferSize = metalBuffer.length
        computeCommandEncoder.setBytes(&utf8BufferSize, length: MemoryLayout<Int>.size, index: 2)
        computeCommandEncoder.setComputePipelineState(computePipelineState)

        // Calculate the number of threads and threadgroups
        let threadGroupSize = MTLSize(
            width: computePipelineState.threadExecutionWidth,
            height: 1,
            depth: 1
        )
        
        let threadGroupsWidth = (metalBuffer.length + threadGroupSize.width - 1) / threadGroupSize.width
        let threadGroups = MTLSize(
            width: threadGroupsWidth,
            height: 1,
            depth: 1
        )

        // Dispatch the compute kernel
        computeCommandEncoder.dispatchThreadgroups(
            threadGroups,
            threadsPerThreadgroup: threadGroupSize
        )

        // Finalize encoding and commit the command buffer
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Here you can read back the data from 'outputBuffer' if needed
        print("Output Buffer: \(outputBuffer)")

        // Get a pointer to the data in the buffer. calculate the number of elements
        let contents = outputBuffer.contents()
        let numberOfElements = outputBuffer.length / MemoryLayout<GlyphMapKernelOut>.stride

        // Bind the memory to the correct type
        let pointer = contents.bindMemory(to: GlyphMapKernelOut.self, capacity: numberOfElements)

        var scalarView = String.UnicodeScalarView()
        for i in 0..<numberOfElements {
            let glyph = pointer[i] // Access each GlyphMapKernelOut
            // Process 'glyph' as needed
            guard let scalar = UnicodeScalar(glyph.sourceValue)
            else { continue }
            scalarView.append(scalar)
        }
        let scalarString = String(scalarView)
        
        return scalarString
    }

    func convertUTF8toUTF32(utf8Data: Data) -> [UInt32] {
        var utf32Array: [UInt32] = []
        var utf8Generator = utf8Data.makeIterator()
        
        while let byte = utf8Generator.next() {
            let codePoint: UInt32
            
            if byte & 0x80 == 0x00 { // 1-byte sequence
                codePoint = UInt32(byte)
            } else if byte & 0xE0 == 0xC0 { // 2-byte sequence
                let byte1 = UInt32(byte & 0x1F) << 6
                let byte2 = UInt32(utf8Generator.next()! & 0x3F)
                codePoint = byte1 | byte2
            } else if byte & 0xF0 == 0xE0 { // 3-byte sequence
                let byte1 = UInt32(byte & 0x0F) << 12
                let byte2 = UInt32(utf8Generator.next()! & 0x3F) << 6
                let byte3 = UInt32(utf8Generator.next()! & 0x3F)
                codePoint = byte1 | byte2 | byte3
            } else if byte & 0xF8 == 0xF0 { // 4-byte sequence
                let byte1 = UInt32(byte & 0x07) << 18
                let byte2 = UInt32(utf8Generator.next()! & 0x3F) << 12
                let byte3 = UInt32(utf8Generator.next()! & 0x3F) << 6
                let byte4 = UInt32(utf8Generator.next()! & 0x3F)
                codePoint = byte1 | byte2 | byte3 | byte4
            } else {
                fatalError("Invalid UTF-8 sequence")
            }
            
            utf32Array.append(codePoint)
        }
        
        return utf32Array
    }

  
    @discardableResult
    func consume(url: URL) -> CodeGrid {
        guard !Self.__TEST_ASYNC__ else {
            return __asyncConsume(url: url)
        }
        
        // MARK: --- BRING THE METAL ---
//        ___BRING_THE_METAL__(url)
        // MARK: --- :horns: -----------
        
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
    
    private func __asyncConsume(url: URL) -> CodeGrid {
        let sem = DispatchSemaphore(value: 0)
        Task(priority: .userInitiated) {
            await acceleratedConsume(url: url)
            sem.signal()
        }
        sem.wait()
        return targetGrid
    }
    
    func consumeText(textPath: URL) -> CodeGrid {
        guard let fullString = try? String(contentsOf: textPath) else {
            return targetGrid
        }
        var nodes = CodeGridNodes()
        let id = "raw-text-path-\(UUID().uuidString)"
        write(fullString, id, NSUIColor.white, &nodes)
        targetGrid.tokenCache[id] = nodes
        return targetGrid
    }
    
    func consumeText(text fullString: String) -> CodeGrid {
        var nodes = CodeGridNodes()
        let id = "raw-text-\(UUID().uuidString)"
        write(fullString, id, NSUIColor.white, &nodes)
        targetGrid.tokenCache[id] = nodes
        return targetGrid
    }
    
    // --> cmd+f 'slow-stuff'
    func consume(rootSyntaxNode: Syntax) {
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
    
    func write(
        _ string: String,
        _ nodeID: NodeSyntaxID,
        _ color: NSUIColor,
        _ writtenNodeSet: inout CodeGridNodes
    ) {
        for newCharacter in string {
//            let glyphKey = GlyphCacheKey(source: newCharacter, color)
            
            let glyphKey = GlyphCacheKey.fromCache(source: newCharacter, color)
            if let node = writer.writeGlyphToState(glyphKey) {
                node.meta.syntaxID = nodeID
                writtenNodeSet.append(node)
                targetCollection.renderer.insert(node)
            } else {
                print("nooooooooooooooooooooo!")
            }
        }
    }
    
    
    func acceleratedConsume(
        url: URL
    ) async {
        let reader = SplittingFileReader(targetURL: url)
        let stream = reader.indexingAsyncLineStream()
        
        let id = "raw-text-\(UUID().uuidString)"
        
        let glyphKey = GlyphCacheKey(source: "\n", .white)
        guard let lineBreakNode = writer.writeGlyphToState(glyphKey) else {
            return
        }
        let lineBreakSize = lineBreakNode.quadSize
        
        var made = [[GlyphNode]]()
        for await (line, lineOffset) in stream {
            let result = targetCollection.renderer.insertLineRaw(
                line: line,
                lineOffset: lineOffset,
                lineOffsetSize: lineBreakSize,
                writer: writer,
                rawId: id
            )
            made.append(result)
        }
//        targetGrid.tokenCache[id] = made.flatMap { $0 }
        targetGrid.updateBackground()
        targetCollection.setRootMesh()
    }
}

/* MARK: - slow-stuff
 Observation:
    - linearly advancing characters is slow to render
    - we rely on the order of nodes to render one by one
    - each token contains an absolute position and a length
    - it may be possible to render the text, then associate each utf index with the cached syntax
    -- so: split lines, for each character, get index (map it?)
    -- maybe the splitter needs to emit utf indices per line, and I map them
 ** token.position.utf8Offset
 
 let lineReader = LineReader()
 for line in lineReader {
    renderLine() // <--- 'rendering' in this case is just building out the glyphs; capture glyphs?
                 // Each line could be a separately managed item... meh... JSON kills that.
                 // Indexing in seems correct, but I have to parse and to render at the same time.
                 // I want to do both at the same time for performance but...
                 // maybe I just don't right now, and just deal with rendering.
 }
 
 -- 'consumeSyntax'
 The trick here is that I'm directly mapping the syntax token to the result set of nodes.
 However, since I can get the UTF index out of the line reader (probably), I can map each index
 to the corresponding node instead:
    0: 'i' -> Token(import statement) -> Node(x)
    1: 'm' -> Token(import statement) -> Node(x+1)
    2: 'p' -> Token(import statement) -> Node(x+2)
    3: 'o' -> Token(import statement) -> Node(x+3)
    4: 'r' -> Token(import statement) -> Node(x+5)
    5: 't' -> Token(import statement) -> Node(x+6)
 
 So...
 In parallel:
    splitting reader -> split lines -> async kickoff per line
        -> generate [UTF8Index: GlyphNode] (another map, hooray, lol)
        -> RETURN the map, and then merge together at the end - avoid locking if possible
 
 In parallel(??):
    run syntax parser
        -> iterate over tokens (this gives us the correct syntanctic ordering; tree-sitter can sit here
        -> blit the token and the index into a map; the index is the start, soo..
 
 After both:
    combine result maps:
        -> splitting reader has all glyphs; syntax parser has all node position starts
        -> iterate over *syntax tokens* and collect *glyphs*
            --> for each token, get the start index, and check the count
            --> for each next token, look up the node and combine into the current set of nodes
            --> stick the result into `tokenCache'
 */
