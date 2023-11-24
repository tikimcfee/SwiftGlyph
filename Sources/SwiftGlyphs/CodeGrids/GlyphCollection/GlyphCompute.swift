//  
//
//  Created on 11/24/23.
//  

import Foundation
import MetalKit
import MetalLink
import MetalLinkHeaders

extension GlyphCollectionSyntaxConsumer {
    func ___BRING_THE_METAL__(_ fileURL: URL) {
        // Read the file into a Data object
        
//        let data: NSData
//        do {
//            data = try NSData(contentsOf: fileURL, options: .alwaysMapped)
//        } catch {
//            data = NSData()
//            print("Failed to read \(fileURL), returning empty data")
//        }
        
//        let data = String(
//            RAW_ATLAS_STRING_.prefix(10_000)
//        ).data!.nsData
        
        let data = RAW_ATLAS_STRING_.data!.nsData
        
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
        let mappedData = runComputeKernel32(on: metalBuffer)
        let normalStringMap = String(data: data.swiftData, encoding: .utf8)
        
        print("--- Did they blend?? --")
        print(mappedData == normalStringMap)
        print("--- --  *** ***  --  --")
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
            guard glyph.sourceValue > 0,
                  let scalar = UnicodeScalar(glyph.sourceValue)
            else { continue }
            scalarView.append(scalar)
        }
        let scalarString = String(scalarView)
        
        return scalarString
    }
}
