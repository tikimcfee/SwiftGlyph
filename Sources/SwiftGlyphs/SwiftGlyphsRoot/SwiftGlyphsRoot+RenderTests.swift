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

//import Neon
//import TreeSitterSwift
//import SwiftTreeSitter

extension SwiftGlyphRoot {
    
    func setupRenderStreamTest() throws {
        camera.position = LFloat3(0, 0, 300)
        
        // Setup a local current collection to track (this is inefficient, but it's a test..)
        var currentDataCollection: CodeGrid? = nil
        let dataStream = PassthroughSubject<Data, Never>()
        
        // Create a renderer for the data stream.
        let renderer = DataStreamRenderer(
            link: link,
            atlas: GlobalInstances.defaultAtlas,
            compute: GlobalInstances.gridStore.sharedConvert,
            dataStream: dataStream.eraseToAnyPublisher(),
            name: "SGTestDataRenderer"
        )
        
        // This is silly, but really, just replace the 'data window' every time.
        // Yes, I know, I can just replace the buffer, and I will. I also feel the pain.
        renderer.collectionStream.sink { [root] nextCollection in
            if let currentDataCollection {
                root.remove(child: currentDataCollection.rootNode)
            }
            let nextGrid = self.builder
                .createGrid(around: nextCollection)
                .applying {
                    $0.updateBackground()
                    
                    GlobalInstances.gridStore
                        .nodeHoverController
                        .attachPickingStream(to: $0)
                }
            currentDataCollection = nextGrid.translated(dZ: 128)
            root.add(child: nextGrid.rootNode)
        }.store(in: &bag)
        
        GlobalInstances
            .userTextEditHolder
            .$userTextInput
            .receive(on: WorkerPool.shared.nextWorker())
            .removeDuplicates()
            .sink { input in
                let file = AppFiles.file(named: "testStreamData", in: AppFiles.glyphSceneDirectory)
                
                do {
//                    let maxLengthTest = 95
//                    var string = NSAttributedString(input).string
//                    let range = string.strideAll(by: maxLengthTest) {
//                        string.insert("\n", at: $0)
//                    }
                    let string = NSAttributedString(input).string
                    try string.write(
                        to: file,
                        atomically: true,
                        encoding: .utf8
                    )
                    let data = try Data(contentsOf: file)
                    dataStream.send(data)
                } catch {
                    print(error)
                }
                
            }
            .store(in: &bag)
    }
    
    func setupRenderPlanTest() throws {
        camera.position = LFloat3(0, 0, 300)
        
        renderPlanPipeline { url in
            GlobalInstances.defaultLink.gridPickingTexture.pickingPaused = true
            GlobalInstances.rootCustomMTKView.isPaused = true
            GlobalInstances.defaultRenderer.paused = true
            
            doAddFilePath(url)
        }
        
        func doAddFilePath(_ url: URL) {
            GlobalInstances.defaultLink.gridPickingTexture.pickingPaused = true
            GlobalInstances.defaultLink.glyphPickingTexture.pickingPaused = true
            GlobalInstances.rootCustomMTKView.isPaused = true
            GlobalInstances.defaultRenderer.paused = true
            
            RenderPlan(
                mode: .cacheAndLayoutStream,
                rootPath: url,
                editor: editor,
                focus: focus
            )
            .startRender(onRenderComplete)
        }
        
        func onRenderComplete(_ plan: RenderPlan) {
            focus.editor.transformedByAdding(
                .inNextRow(plan.rootGroup.globalRootGrid)
            )
            
            self.root.add(child: plan.targetParent)
            
            GlobalInstances.defaultLink.gridPickingTexture.pickingPaused = false
            GlobalInstances.defaultLink.glyphPickingTexture.pickingPaused = false
            GlobalInstances.rootCustomMTKView.isPaused = false
            GlobalInstances.defaultRenderer.paused = false
            
//            QuickLooper(interval: .milliseconds(16)) { interval in
//                plan.targetParent.rotation.y = cos(Float(interval.rawValue) / 100_000_000) / 1.3
//                plan.targetParent.rotation.x = cos(Float(interval.rawValue) / 50_000_000) / 1.3
//                plan.targetParent.rotation.x += 0.0025
//                plan.targetParent.rotation.z += 0.005
//            }.runUntil { false }
        }
    }
}

// MARK: - Test load pipeline

extension SwiftGlyphRoot {
    func renderPlanPipeline(_ action: @escaping (URL) -> Void) {
        GlobalInstances
            .fileBrowser
            .$fileSelectionEvents
            .compactMap { $0 }
            .sink { event in
                self.onFileEvent(event, action)
            }
            .store(in: &bag)
    }
    
    func onFileEvent(
        _ event: FileBrowserEvent,
        _ action: @escaping (URL) -> Void
    ) {
        let cache = GlobalInstances.gridStore.gridCache
        
        switch event.action {
        case .addToWorld:
            action(event.scope.path)
            
        case .removeFromWorld:
            event.scope.cachedGrid?.applying {
                $0.removeFromParent()
                cache.removeGrid($0)
            }
            
        case .toggle:
            // TODO: Memory leaks baby!
            // The second I started thinking about removing, I knew there'd be leaks. And there are.
            // The grids as files are retained in gridCache, hover controller, et al.
            if let grid = event.scope.cachedGrid {
                grid.derez_global()
            } else {
                action(event.scope.path)
            }
        }
    }
}

let ___RAW___SOURCE___ = """

            //
            //
            //  Created on 12/14/23.
            //

            import Foundation
            import MetalKit
            import MetalLinkHeaders
            import BitHandling
            import Combine

            public struct FileWatchRenderer: MetalLinkReader {
                public let link: MetalLink
                public var atlas: MetalLinkAtlas
                public let compute: ConvertCompute
                public let sourceUrl: URL
                
                public init(
                    link: MetalLink,
                    atlas: MetalLinkAtlas,
                    compute: ConvertCompute,
                    sourceUrl: URL
                ) {
                    self.link = link
                    self.atlas = atlas
                    self.compute = compute
                    self.sourceUrl = sourceUrl
                }

                public func regenerateCollectionForSource() throws -> GlyphCollection {
                    let encodeResult = try compute.executeSingleWithAtlas(
                        source: sourceUrl,
                        atlas: atlas
                    )
                    
                    switch encodeResult.collection {
                    case .built(let result):
                        return result
                        
                    case .notBuilt:
                        return try GlyphCollection(link: link, linkAtlas: atlas)
                    }
                }
            }

            public class DataStreamRenderer: MetalLinkReader {
                public typealias DataStream = AnyPublisher<Data, Never>
                public typealias CollectionStream = AnyPublisher<GlyphCollection, Never>
                
                public let link: MetalLink
                public var atlas: MetalLinkAtlas
                public let compute: ConvertCompute
                public let name: String
                
                public let sourceStream: DataStream
                public let collectionStream: CollectionStream
                
                private var token: Any?
                
                public init(
                    link: MetalLink,
                    atlas: MetalLinkAtlas,
                    compute: ConvertCompute,
                    dataStream: DataStream,
                    name: String
                ) {
                    self.link = link
                    self.atlas = atlas
                    self.compute = compute
                    self.name = name
                    self.sourceStream = dataStream
                    self.collectionStream = dataStream
                        .receive(on: DispatchQueue.global())
                        .compactMap { data in
                            do {
                                return try Self.regenerateCollection(
                                    name: name,
                                    for: data,
                                    compute: compute,
                                    atlas: atlas,
                                    link: link
                                )
                            } catch {
                                print(error)
                                return nil
                            }
                        }
                        .share()
                        .eraseToAnyPublisher()
                }

                private static func regenerateCollection(
                    name: String,
                    for data: Data,
                    compute: ConvertCompute,
                    atlas: MetalLinkAtlas,
                    link: MetalLink
                ) throws -> GlyphCollection {
                    let encodeResult = try compute.executeDataWithAtlas(
                        name: name,
                        source: data,
                        atlas: atlas
                    )
                    
                    switch encodeResult.collection {
                    case .built(let result):
                        return result
                        
                    case .notBuilt:
                        return try GlyphCollection(link: link, linkAtlas: atlas)
                    }
                }
            }


"""

extension String {
    func stride(
        from start: Index,
        to end: Index,
        by stride: Int
    ) -> [Index] {
        var result = [Index]()
        self.stride(
            from: start,
            to: end,
            by: stride,
            into: &result
        )
        return result
    }
    
    func stride(
        from start: Index,
        to end: Index,
        by stride: Int,
        into receiver: inout [Index]
    ) {
        self.stride(
            from: start,
            to: end,
            by: stride,
            into: { receiver.append($0) } 
        )
    }

    func stride(
        from start: Index,
        to end: Index,
        by stride: Int,
        into receiver: (Index) -> Void
    ) {
        var current = start
        while current < end {
            receiver(current)
            
            guard let nextIndex = index(current, offsetBy: stride, limitedBy: end)
            else { break }
            
            current = nextIndex
        }
    }
    
    func strideAll(
        by stride: Int,
        _ receiver: (Index) -> Void
    ) {
        self.stride(
            from: startIndex,
            to: endIndex,
            by: stride,
            into: receiver
        )
    }
}
