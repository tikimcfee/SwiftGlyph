//  
//
//  Created on 11/24/23.
//  

import Foundation
import MetalKit
import MetalLink
import MetalLinkHeaders

public class GlyphCompute {
//    func ___BRING_THE_METAL__(_ fileURL: URL) {
////        let data: NSData
////        do {
////            data = try NSData(contentsOf: fileURL, options: .alwaysMapped)
////        } catch {
////            data = NSData()
////            print("Failed to read \(fileURL), returning empty data")
////        }
//        
//        let data = "🇵🇷".data!.nsData
//        
////        let data = String(
////            RAW_ATLAS_STRING_.prefix(60_000)
////        ).data!.nsData
////
////        let data = RAW_ATLAS_STRING_.data!.nsData
//    }
    
    func runComputeKernel32(on data: NSData, writer: GlyphCollectionWriter) {
//        let defaultLibrary = GlobalInstances.defaultLink.defaultLibrary
//        let device = GlobalInstances.defaultLink.device
//        let commandQueue = GlobalInstances.defaultLink.commandQueue
        
        guard let outputBuffer = try? ConvertCompute(
            link: GlobalInstances.defaultLink
        ).execute(inputData: data)
        else {
            print("It broke =(")
            return
        }
        
        // Get a pointer to the data in the buffer. calculate the number of elements
        let contents = outputBuffer.contents()
        let numberOfElements = outputBuffer.length / MemoryLayout<GlyphMapKernelOut>.stride

        // Bind the memory to the correct type
        let pointer = contents.bindMemory(
            to: GlyphMapKernelOut.self,
            capacity: numberOfElements
        )

        var scalarView = String.UnicodeScalarView()
        for i in 0..<numberOfElements {
            let glyph = pointer[i]
            guard glyph.sourceValue > 0, // Assert not a terminator
                  let scalar = UnicodeScalar(glyph.sourceValue)
            else { continue }

            scalarView.append(scalar)
            
            let pairOut = writer.addGlyphToAtlas(scalar)
            if let pair = pairOut.0 {
                pointer[i].textureDescriptorU = pair.u
                pointer[i].textureDescriptorV = pair.v
            }
            if let bundle = pairOut.1 {
                pointer[i].textureSize = bundle.texture.simdSize
            }
        }
        
        print("The atlas has been filled")
    }
}

extension GlyphCollectionSyntaxConsumer {
    func ___BRING_THE_METAL__(_ fileURL: URL) {
        GlyphCompute().runComputeKernel32(
            on: try! NSData(contentsOf: fileURL),
            writer: writer
        )
    }
}

public enum ComputeError: Error {
    case missingFunction(String)
    case bufferCreationFailed
    case startupFailure
}

public class ConvertCompute: MetalLinkReader {
    public let link: MetalLink
    public init(link: MetalLink) { self.link = link }
    
    private let name = "utf8ToUtf32Kernel"
    private lazy var kernelFunction = library.makeFunction(name: name)
    private lazy var commandBuffer = commandQueue.makeCommandBuffer()
    private lazy var computeCommandEncoder = commandBuffer?.makeComputeCommandEncoder()
    
    // Create a pipeline state from the kernel function, using the default name
    private func makePipelineState() throws -> MTLComputePipelineState {
        guard let kernelFunction else { throw ComputeError.missingFunction(name) }
        return try device.makeComputePipelineState(function: kernelFunction)
    }
    
    // Create a Metal buffer from the Data object
    private func makeInputBuffer(_ data: NSData) throws -> MTLBuffer {
        guard let metalBuffer = device.makeBuffer(bytes: data.bytes, length: data.count, options: [] )
        else { throw ComputeError.bufferCreationFailed }
        return metalBuffer
    }
    
    // Create an output buffer matching the GlyphMapKernelOut structure
    // MARK: NOTE / TAKE CARE / BE AWARE [Buffer size]
    // Check it out the length is div 4 so the end buffer is
    private func makeOutputBuffer(from inputBuffer: MTLBuffer) throws -> MTLBuffer {
        let safeSize = max(1, inputBuffer.length)
        let safeOutputBufferSize = safeSize * MemoryLayout<GlyphMapKernelOut>.stride
        guard let outputBuffer = device.makeBuffer(length: safeOutputBufferSize, options: [])
        else { throw ComputeError.bufferCreationFailed }
        return outputBuffer
    }
    
    public func makeGraphemeAtlasBuffer(
        size: Int = 1_000_512
    ) throws -> (MTLBuffer, UnsafeMutablePointer<GlyphMapKernelAtlasIn>) {
        guard let metalBuffer = device.makeBuffer(
            length: size * MemoryLayout<GlyphMapKernelAtlasIn>.stride,
            options: [ /*.cpuCacheModeWriteCombined*/ ] // TODO: is this a safe performance trick?
        ) else { throw ComputeError.bufferCreationFailed }
        return (
            metalBuffer,
            metalBuffer.boundPointer(as: GlyphMapKernelAtlasIn.self, count: 1_000_512)
        )
    }

    // Give me .utf8 text data and I'll do weird things to a buffer and give it back.
    public func execute(
        inputData: NSData
    ) throws -> MTLBuffer {
        guard let computeCommandEncoder, let commandBuffer
        else { throw ComputeError.startupFailure }
        
        let inputUTF8TextDataBuffer = try makeInputBuffer(inputData)
        let outputUTF32ConversionBuffer = try makeOutputBuffer(from: inputUTF8TextDataBuffer)
        let computePipelineState = try makePipelineState()

        // Set the compute kernel's parameters
        computeCommandEncoder.setBuffer(inputUTF8TextDataBuffer, offset: 0, index: 0)
        computeCommandEncoder.setBuffer(outputUTF32ConversionBuffer, offset: 0, index: 1)
        
        // Pass the size of the UTF-8 buffer as a constant
        var utf8BufferSize = inputUTF8TextDataBuffer.length
        computeCommandEncoder.setBytes(&utf8BufferSize, length: MemoryLayout<Int>.size, index: 2)
        computeCommandEncoder.setComputePipelineState(computePipelineState)
        
        // Calculate the number of threads and threadgroups
        // TODO: Explain why (boundsl, performance, et al), and make this better; this is probably off
        let threadGroupSize = MTLSize(width: computePipelineState.threadExecutionWidth, height: 1, depth: 1)
        let threadGroupsWidthCeil = (inputUTF8TextDataBuffer.length + threadGroupSize.width - 1) / threadGroupSize.width
        let threadGroupsPerGrid = MTLSize(width: threadGroupsWidthCeil, height: 1, depth: 1)
        
        // Dispatch the compute kernel
        computeCommandEncoder.dispatchThreadgroups(
            threadGroupsPerGrid,
            threadsPerThreadgroup: threadGroupSize
        )

        // Finalize encoding and commit the command buffer
        computeCommandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // Houston we have a buffer.
        return outputUTF32ConversionBuffer
    }
    
    public func cast(
        _ buffer: MTLBuffer
    ) -> (UnsafeMutablePointer<GlyphMapKernelOut>, Int) {
        let numberOfElements = buffer.length / MemoryLayout<GlyphMapKernelOut>.stride
        return (
            buffer.contents().bindMemory(
                to: GlyphMapKernelOut.self,
                capacity: numberOfElements
            ),
            numberOfElements
        )
    }
    
    public func makeString(
        from pointer: UnsafeMutablePointer<GlyphMapKernelOut>,
        count: Int
    ) -> String {
        // TODO: Is there a safe way to initialize with a starting block size?
        var scalarView = String.UnicodeScalarView()
        for index in 0..<count {
            let glyph = pointer[index] // Access each GlyphMapKernelOut
            // Process 'glyph' as needed
            guard glyph.sourceValue > 0,
                  let scalar = UnicodeScalar(glyph.sourceValue)
            else { continue }
            scalarView.append(scalar)
        }
        let scalarString = String(scalarView)
        return scalarString
    }
    
    public func makeGraphemeBasedString(
        from pointer: UnsafeMutablePointer<GlyphMapKernelOut>,
        count: Int
    ) -> String {
        let allUnicodeScalarsInView: String.UnicodeScalarView =
            (0..<count)
                .lazy
                .map { pointer[$0].allSequentialScalars }
                .filter { !$0.isEmpty }
                .map { scalarList in
                    scalarList.lazy.map { scalar in
                        UnicodeScalar(scalar)!
                    }
                }
                .reduce(into: String.UnicodeScalarView()) { view, scalars in
                    view.append(contentsOf: scalars)
                }
        let manualGraphemeString = String(allUnicodeScalarsInView)
        return manualGraphemeString
    }
}


