//
//  SwiftGlyphRoot.swift
//  MetalSimpleInstancing
//
//  `TwoETime` and `2ETRoot`
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//
//  - With thanks to Rick Twohy
//  https://discord.gg/hKPBTbC
//

import Combine
import MetalKit
import SwiftUI
import MetalLink
import BitHandling

extension SwiftGlyphRoot: MetalLinkRendererDelegate {
    public func performDelegatedEncode(with pass: SafeDrawPass) {
        delegatedEncode(in: pass)
    }
}

public class SwiftGlyphRoot: MetalLinkReader {
    public let link: MetalLink
    
    var bag = Set<AnyCancellable>()
    
    lazy var root = RootNode(camera)
    
    var camera: DebugCamera {
        GlobalInstances.debugCamera
    }
    
    var editor: WorldGridEditor {
        GlobalInstances.gridStore.editor
    }
    
    var focus: WorldGridFocusController {
        GlobalInstances.gridStore.worldFocusController
    }
    
    var builder: CodeGridGlyphCollectionBuilder {
        GlobalInstances.gridStore.builder
    }
    
    public init(link: MetalLink) throws {
        self.link = link
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        camera.interceptor.onNewFileOperation = handleDirectory
        camera.interceptor.onNewFocusChange = handleFocus
        
        GlobalInstances.defaultAtlas.load()
        
        try setupRenderPlanTest()
//        try setupRenderStreamTest()
//        try setupWordWarePLA()
        
//        QuickLooper(interval: .milliseconds(1000)) {
//            print("~~ Debug loop ~~")
//        }.runUntil { false }
    }
    
    func delegatedEncode(in sdp: SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
        // TODO: Make update and render a single pass to avoid repeated child loops
        root.update(deltaTime: dT)
        root.render(in: sdp)
    }
    
    func handleFocus(_ direction: SelfRelativeDirection) {
        let focused = editor.lastFocusedGrid
        guard let current = focused else { return }
        
        let grids = editor.snapping.gridsRelativeTo(current, direction)
        
        if let first = grids.first {
            focus.state = .set(first.targetGrid)
        } else {
            focus.state = .set(current)
        }
    }
    
    func handleDirectory(_ file: FileOperation) {
        switch file {
        case .openDirectory:
            openDirectory { file in
                guard let url = file.parent else { return }
                GlobalInstances.fileBrowser.setRootScope(url)
            }
        }
    }
}
