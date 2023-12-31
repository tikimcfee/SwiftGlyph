//
//  SwiftGlyphsTests.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 1/28/23.
//

import Combine
import MetalKit
import SwiftUI
import SwiftParser
import SwiftSyntax
import MetalLink
import BitHandling

extension SwiftGlyphsRoot {
    
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
            RenderPlan(
                mode: .cacheAndLayout,
                rootPath: url,
                builder: self.builder,
                editor: self.editor,
                focus: self.focus,
                hoverController: GlobalInstances.gridStore.nodeHoverController
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

extension SwiftGlyphsRoot {
    func basicGridPipeline(_ childPath: URL) -> GlyphCollectionSyntaxConsumer {
        let consumer = builder.createConsumerForNewGrid()
        consumer.consume(url: childPath)
        consumer.targetGrid.fileName = childPath.fileName
        
        GlobalInstances.gridStore.nodeHoverController
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
        GlobalInstances.fileBrowser.$fileSelectionEvents.sink { event in
            switch event {
            case let .newMultiCommandRecursiveAllLayout(rootPath, _):
                action(rootPath)
                
            case let .newSingleCommand(url, .focusOnExistingGrid):
                if let grid = self.builder.sharedGridCache.get(url) {
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
