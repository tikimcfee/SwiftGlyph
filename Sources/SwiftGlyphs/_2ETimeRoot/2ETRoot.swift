//
//  2ETRoot.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//
//  - With thanks to Rick Twohy
//  https://discord.gg/hKPBTbC
//

import Combine
import MetalKit
import SwiftUI
import SwiftParser
import SwiftSyntax
import MetalLink
import BitHandling

extension TwoETimeRoot: MetalLinkRendererDelegate {
    public func performDelegatedEncode(with pass: inout SafeDrawPass) {
        delegatedEncode(in: &pass)
    }
}

public class TwoETimeRoot: MetalLinkReader {
    public let link: MetalLink
    
    var bag = Set<AnyCancellable>()
    
    lazy var root = RootNode(camera)
    
    lazy var builder = try! CodeGridGlyphCollectionBuilder(
        link: link,
        sharedSemanticMap: GlobalInstances.gridStore.globalSemanticMap,
        sharedTokenCache: GlobalInstances.gridStore.globalTokenCache,
        sharedGridCache: GlobalInstances.gridStore.gridCache
    )
    
    var camera: DebugCamera {
        GlobalInstances.debugCamera
    }
    
    var editor: WorldGridEditor {
        GlobalInstances.gridStore.editor
    }
    
    var focus: WorldGridFocusController {
        GlobalInstances.gridStore.worldFocusController
    }
    
    public init(link: MetalLink) throws {
        self.link = link
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        camera.interceptor.onNewFileOperation = handleDirectory
        camera.interceptor.onNewFocusChange = handleFocus
        
//        try setupNodeChildTest()
//        try setupNodeBackgroundTest()
//        try setupBackgroundTest()
        try setupRenderPlanTest()
//        try setupTriangleStripTest()
//        try setupWordWare()
//        try setupWordWareSentence()
//        try setupWordWarePLA()
//        try setupDictionaryTest()
//        try setupFastGraphTest()
        
        GlobalInstances.defaultAtlas.load()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
        // TODO: Make update and render a single pass to avoid repeated child loops
        root.update(deltaTime: dT)
        root.render(in: &sdp)
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
                
                // TODO: Is this a thing now?
                self.tryLSPLoad(url)
            }
        }
    }
    
    func tryLSPLoad(_ url: URL) {
        Task {
            do {
                // This loads up the last server into the shared wrapper as an enum instance.
                // That's a pretty dirty trick.
                try await GlobalInstances.gridStore.sharedLsp.quickNewServer(at: url)
                
                guard let folder = try CodeFolder(url, codeFileEndings: ["swift"]) else {
                    return
                }
                
                guard case let .loaded(server) = GlobalInstances.gridStore.sharedLsp.state else {
                    return
                }
                
                let result = try await folder.retrieveSymbolsAndReferences(
                    at: url,
                    from: server,
                    codebaseRootFolder: url
                )
                
                print(result)
            } catch {
                print(error)
            }
        }
    }
}
