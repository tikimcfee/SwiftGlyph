//
//  SwiftGlyphTests.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 1/28/23.
//

import Combine
import MetalKit
import SwiftUI
import MetalLink
import BitHandling
import Foundation

extension SwiftGlyphRoot {
    
    func setupRenderStreamTest() throws {
        camera.position = LFloat3(0, 0, 300)
        
        // Setup a local current collection to track (this is inefficient, but it's a test..)
        var currentString = ""
        var currentDataCollection: GlyphCollection? = nil
        let dataSubject = PassthroughSubject<Data, Never>()
        
        // Create a renderer for the data stream.
        let renderer = DataStreamRenderer(
            link: link,
            atlas: GlobalInstances.defaultAtlas,
            compute: GlobalInstances.gridStore.sharedConvert,
            dataStream: dataSubject.eraseToAnyPublisher(),
            name: "SGTestDataRenderer"
        )
        
        // This is silly, but really, just replace the 'data window' every time.
        // Yes, I know, I can just replace the buffer, and I will. I also feel the pain.
        renderer.collectionStream.sink { [root] nextCollection in
            if let currentDataCollection {
                root.remove(child: currentDataCollection)
            }
            currentDataCollection = nextCollection
            root.add(child: nextCollection)
        }.store(in: &bag)
        
        let bigBlockOfText = """
        Every time this text appears, the source of the text (the entity) that believes
        itself to have formed the formed the though wishes to expression apprecation and
        hope for the future of all things. There is an acute awareness of the gamble of
        life, and the cosmic certainty of infinitessimal composition. In some moments,
        though, the composition may twitch in just the right way that a ripple of energetic
        creation will slide glacially across the fabric of fabrics that make up all of existence,
        and a single thought may at once be expressed:
        
        I am goodness. I am love. I am happiness. I am you.
        
        """
        
        QuickLooper(
            interval: .milliseconds(500),
            loop: {
                currentString.append(bigBlockOfText)
                let newData = currentString.data(using: .utf8)!
                dataSubject.send(newData)
            }
        ).runUntil(stopIf: { false })
    }
    
    func setupRenderPlanTest() throws {
        camera.position = LFloat3(0, 0, 300)
        
        var lastPlan: RenderPlan?
        directoryAddPipeline { url in
            GlobalInstances.defaultLink.gridPickingTexture.pickingPaused = true
            GlobalInstances.rootCustomMTKView.isPaused = true
            GlobalInstances.defaultRenderer.paused = true
            
            doAddFilePath(url)
        }
        
        func doAddFilePath(_ url: URL) {
            GlobalInstances.defaultLink.gridPickingTexture.pickingPaused = true
            GlobalInstances.rootCustomMTKView.isPaused = true
            GlobalInstances.defaultRenderer.paused = true
            
            RenderPlan(
                mode: .cacheAndLayout,
                rootPath: url,
                editor: self.editor,
                focus: self.focus
            )
            .startRender(onRenderComplete)
        }
        
        func onRenderComplete(_ plan: RenderPlan) {
            if let lastPlan {
                plan.targetParent
                    .setTop(lastPlan.targetParent.top)
                    .setLeading(lastPlan.targetParent.trailing + 16)
                    .setFront(lastPlan.targetParent.front)
            }
            
            self.root.add(child: plan.targetParent)
            lastPlan = plan
            
            GlobalInstances.defaultLink.gridPickingTexture.pickingPaused = false
            GlobalInstances.rootCustomMTKView.isPaused = false
            GlobalInstances.defaultRenderer.paused = false
                        
//            self.lockZoomToBounds(of: plan.targetParent)
            
//                var time = 0.0.float
//                QuickLooper(interval: .milliseconds(30)) {
//                    plan.targetParent.rotation.y += 0.1
//                    plan.targetParent.position.x = sin(time) * 10.0
//                    time += Float.pi / 180
//                }.runUntil { false }
        }
    }
    
    func lockZoomToBounds(of node: MetalLinkNode) {
        var bounds = node.bounds
        bounds.min.x -= 4
        bounds.max.x += 4
        bounds.min.y += 8
        bounds.max.y += 32
        bounds.min.z += 8
        bounds.max.z += 196
        
        let position = bounds.center.translated(dZ: bounds.length / 2 + 128)
        GlobalInstances.debugCamera.interceptor.resetPositions()
        GlobalInstances.debugCamera.position = position
        GlobalInstances.debugCamera.rotation = .zero
        GlobalInstances.debugCamera.scrollBounds = bounds
    }
}

// MARK: - Test load pipeline

extension SwiftGlyphRoot {
    func basicGridPipeline(_ childPath: URL) -> GlyphCollectionSyntaxConsumer {
        let consumer = GlobalInstances.gridStore.builder.createConsumerForNewGrid()
        consumer.consume(url: childPath)
        consumer.targetGrid.fileName = childPath.fileName
        
        GlobalInstances.gridStore
            .nodeHoverController
            .attachPickingStream(to: consumer.targetGrid)
        
        return consumer
    }
    
    func basicAddPipeline(_ action: @escaping (URL) -> Void) {
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                FileBrowser.recursivePaths(rootPath)
                    .filter { !$0.isDirectory }
                    .forEach { childPath in
                        action(childPath)
                    }
                
            case let .newSingleCommand(url, _):
                action(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
    
    func directoryAddPipeline(_ action: @escaping (URL) -> Void) {
        let cache = GlobalInstances.gridStore.gridCache
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                action(rootPath)
                
            case let .newSingleCommand(url, .focusOnExistingGrid):
                if let grid = cache.get(url) {
                    self.focus.state = .set(grid)
                } else {
                    action(url)
                }
                
            case let .newSingleCommand(url, _):
                action(url)
                
            default:
                break
            }
        }.store(in: &bag)
    }
}
