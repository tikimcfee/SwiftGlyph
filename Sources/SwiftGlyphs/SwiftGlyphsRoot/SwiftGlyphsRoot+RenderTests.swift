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

import Neon
import TreeSitterSwift
import SwiftTreeSitter

extension SwiftGlyphRoot {
    
    func setupRenderStreamTest() throws {
        camera.position = LFloat3(0, 0, 300)
        
        // Setup a local current collection to track (this is inefficient, but it's a test..)
        var currentStringData = "".data(using: .utf8)!
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
        
//        let bigBlockOfText = """
//        Every time this text appears, the source of the text (the entity) that believes
//        itself to have formed the formed the though wishes to expression apprecation and
//        hope for the future of all things. There is an acute awareness of the gamble of
//        life, and the cosmic certainty of infinitessimal composition. In some moments,
//        though, the composition may twitch in just the right way that a ripple of energetic
//        creation will slide glacially across the fabric of fabrics that make up all of existence,
//        and a single thought may at once be expressed:
//        
//        I am goodness. I am love. I am happiness. I am you.
//        
//        """
        
        let language = Language(language: tree_sitter_swift())
        
        let parser = Parser()
        try parser.setLanguage(language)
        
        let testFile = ___RAW___SOURCE___
        let tree = parser.parse(testFile)!
        
        let queryUrl = Bundle.main
                      .resourceURL?
                      .appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle")
                      .appendingPathComponent("Contents/Resources/queries/highlights.scm")
        
        let query = try language.query(contentsOf: queryUrl!)
        let cursor = query.execute(node: tree.rootNode!, in: tree)
        
        // I'm gonna setup a pipe to just render any stream of UTF-8 data.
        // Teehee.
        
//        var rawOutput = ""
        var rawOutput: [String] = []
        func addLine(_ message: String) {
            rawOutput.append(message + "\n")
        }
        for match in cursor {
            addLine("match: \(match.id), \(match.patternIndex)")
            for capture in match.captures {
                addLine("\t>> [\(capture)] <<")
                addLine("\t\t\(capture.nameComponents)")
                addLine("\t\t\(capture.name ?? "<!> no name")")
            }
        }
        var iterator = rawOutput.makeIterator()
        var next = iterator.next()
        
        QuickLooper(
            interval: .milliseconds(10),
            queue: .global()
        ) {
            guard let toAdd = next else { return }
            next = iterator.next()
            
            let addData = toAdd.data(using: .utf8)!
            currentStringData.append(addData)
            
            dataSubject.send(currentStringData)
        }.runUntil(
            stopIf: { next == nil }
        )
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
