//
//  RenderPlan.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/21/22.
//

import Foundation
import OrderedCollections
import MetalLink
import MetalKit
import BitHandling
import Combine

class RenderPlan: MetalLinkReader {
    var link: MetalLink { GlobalInstances.defaultLink }
    var statusObject: AppStatus { GlobalInstances.appStatus }
    var compute: ConvertCompute { GlobalInstances.gridStore.sharedConvert }
    var builder: CodeGridGlyphCollectionBuilder { GlobalInstances.gridStore.builder }
    var gridCache: GridCache { GlobalInstances.gridStore.gridCache }
    var hoverController: MetalLinkHoverController { GlobalInstances.gridStore.nodeHoverController }
    var colorizeOnLoad: Bool { GlobalLiveConfig.Default.colorizeOnOpen }
    
    var bag = Set<AnyCancellable>()
    var targetParent: MetalLinkNode {
        rootGroup.globalRootGrid.rootNode
    }
    
    var rootGroup: CodeGridGroup {
        let rootGroup = rootPath.isDirectory
            ? state.directoryGroups[rootPath]
            : state.directoryGroups[rootPath.deletingLastPathComponent()]
        
        // Now look for root group. Big problems if we miss it.
        guard let rootGroup else {
            fatalError("But where did the root go")
        }
        
        return rootGroup
    }
    
    class State {
        var directoryGroups = [URL: CodeGridGroup]()
    }
    let state = State()
    
    enum Mode {
        case cacheOnly
        case layoutOnly
        case cacheAndLayout
        case cacheAndLayoutStream
    }
    let mode: Mode
    
    let rootPath: URL
    let editor: WorldGridEditor
    let focus: WorldGridFocusController
    
    init(
        mode: Mode,
        rootPath: URL,
        editor: WorldGridEditor,
        focus: WorldGridFocusController
    ) {
        self.mode = mode
        self.rootPath = rootPath
        self.editor = editor
        self.focus = focus
    }
    
    func startRender(
        _ onComplete: @escaping (RenderPlan) -> Void = { _ in }
    ) {
        WorkerPool.shared.nextConcurrentWorker().async {
            self.onStart(onComplete)
        }
    }
    
    private func onStart(
        _ onComplete: @escaping (RenderPlan) -> Void
    ) {
        statusObject.resetProgress()
        
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Your computer is about to explode <3"
            $0.isActive = true
        }
        
        renderTaskForMode(onComplete)
        
        statusObject.update {
            $0.message = "Render complete!"
            $0.currentValue = $0.totalValue
            $0.isActive = false
        }
    }
}

private extension RenderPlan {
    func renderTaskForMode(
        _ onComplete: @escaping (RenderPlan) -> Void
    ) {
        switch mode {
        case .cacheAndLayoutStream:
            WatchWrap.startTimer("\(self.rootPath.fileName)")
            computeAllTheGrids_stream({ _ in
                WatchWrap.stopTimer("\(self.rootPath.fileName)")
                self.bag = .init()
                onComplete(self)
            })
            
        case .cacheAndLayout:
            WatchWrap.startTimer("\(rootPath.fileName)")
            cacheGrids_V2()
            doGridLayout()
            onComplete(self)
            WatchWrap.stopTimer("\(rootPath.fileName)")

        case .cacheOnly:
            WatchWrap.startTimer("\(rootPath.fileName)")
            cacheGrids_V2()
            onComplete(self)
            WatchWrap.stopTimer("\(rootPath.fileName)")
            
        case .layoutOnly:
            WatchWrap.startTimer("\(rootPath.fileName)")
            doGridLayout()
            onComplete(self)
            WatchWrap.stopTimer("\(rootPath.fileName)")
        }
    }
    
    func doGridLayout() {        
        statusObject.update {
            $0.totalValue += 1
            $0.message = "Starting layout..."
        }
        rootGroup.applyAllConstraints()
        
        statusObject.update {
            $0.currentValue += 1
            $0.totalValue += 1
            $0.message = "Jump in the line..."
        }
        
        rootGroup.addLines(root: rootGroup.asNode)
        rootGroup.addAllWalls()
    }
}

private extension RenderPlan {
    func cacheGrids_V2() {
        computeAllTheGrids()
    }
    
    func computeAllTheGrids() {
        // Gather all the files and directories at once.
        // Threads. Heh.
        var allFileURLs = [URL]()
        var allDirectoryURLs = [URL]()
        let rootIsFile = rootPath.isSupportedFileType
        
        if rootIsFile {
            // Render the root file as well
            allFileURLs.append(rootPath)
            let parent = rootPath.deletingLastPathComponent()
            if parent.isDirectory {
                allDirectoryURLs.append(parent)
            }
        } else if rootPath.isDirectory {
            // Render the root file as normal directory, then look for it
            allDirectoryURLs.append(rootPath)
            
            // Find all recursive files and directories of the root.
            // Sort them out.
            FileBrowser
                .recursivePaths(rootPath)
                .forEach {
                    if $0.isDirectory {
                        allDirectoryURLs.append($0)
                    } else {
                        allFileURLs.append($0)
                    }
                }
        }
        
        // Check we have something to render
        guard !allFileURLs.isEmpty || !allDirectoryURLs.isEmpty else {
            statusObject.update {
                $0.currentValue += 1
                $0.message = "Didn't find any supported files to render."
            }
            return
        }
        
        statusObject.update {
            $0.message = "Found \(allFileURLs.count) files to render."
        }
        
        // Setup all the directory relationships first
        cacheCodeGroups(for: allDirectoryURLs)
        rootGroup.assignAsRootParent()
        
        // Then ask kindly of the gpu to go 'ham'
        do {
            onDebugStart()
            let allMappedAtlasResults = try compute.executeManyWithAtlas(
                sources: allFileURLs,
                atlas: builder.atlas,
                onEvent: { [statusObject] event in
                    statusObject.update {
                        switch event {
                        case .bufferMapped(let string):
                            $0.totalValue += 1
                            $0.message = "File mapped to data: \(string)"
                            
                        case .layoutEncoded(let string):
                            $0.message = "Atlas layout encoded: \(string)"
                            
                        case .copyEncoded(let string):
                            $0.message = "Preparing glyph copy: \(string)"
                            
                        case .collectionReady(let string):
                            $0.message = "Collection made ready: \(string)"
                        }
                    }
                }
            )

            for collectionResult in allMappedAtlasResults {
                cacheCollectionAsGrid(from: collectionResult)
                statusObject.update {
                    $0.message = "Completed grid creation: \(collectionResult.sourceURL.lastPathComponent)"
                    $0.currentValue += 1
                }
            }
            onDebugStop()
            
        } catch {
            fatalError("Crash for now, my man: \(error)")
        }
    }
    
    func computeAllTheGrids_stream(
        _ onComplete: @escaping (RenderPlan) -> Void
    ) {
        // Gather all the files and directories at once.
        // Threads. Heh.
        var allFileURLs = [URL]()
        var allDirectoryURLs = [URL]()
        let rootIsFile = rootPath.isSupportedFileType
        
        if rootIsFile {
            // Render the root file as well
            allFileURLs.append(rootPath)
            let parent = rootPath.deletingLastPathComponent()
            if parent.isDirectory {
                allDirectoryURLs.append(parent)
            }
        } else {
            // Render the root file as normal directory, then look for it
            allDirectoryURLs.append(rootPath)
            
            // Find all recursive files and directories of the root.
            // Sort them out.
            FileBrowser
                .recursivePaths(rootPath)
                .forEach {
                    if $0.isDirectory {
                        allDirectoryURLs.append($0)
                    } else {
                        allFileURLs.append($0)
                    }
                }
        }
        
        // Check we have something to render
        guard !allFileURLs.isEmpty || !allDirectoryURLs.isEmpty else {
            statusObject.update {
                $0.currentValue += 1
                $0.message = "Didn't find any supported files to render."
            }
            return
        }
        
        statusObject.update {
            $0.message = "Found \(allFileURLs.count) files to render."
        }
        
        // Setup all the directory relationships first
        cacheCodeGroups(for: allDirectoryURLs)
        
        // Then ask kindly of the gpu to go 'ham'
        let results = compute.executeManyWithAtlas_Stream(
            atlas: builder.atlas
        )
        let remaining = ConcurrentArray<URL>(allFileURLs)
        
        let cacheStream = results.out
            .handleEvents(
                receiveOutput: { collectionResult in
                    self.cacheCollectionAsGrid(from: collectionResult)
                    remaining.directWriteAccess {
                        $0.removeAll(where: { $0 == collectionResult.sourceURL })
                    }
                    if remaining.isEmpty {
                        self.doGridLayout()
                        onComplete(self)
                    }
                }
            )
        cacheStream.sink(receiveValue: { result in
            print("Completed: \(result.sourceURL.lastPathComponent)")
        }).store(in: &bag)
        
        for url in allFileURLs {
            results.in.send(url)
        }
    }
    
    
    private func onDebugStart(_ captureManager: MTLCaptureManager = .shared()) {
//        do {
//            let captureDescriptor = MTLCaptureDescriptor()
//            captureDescriptor.captureObject = commandQueue
//            captureDescriptor.destination = .developerTools
//            try captureManager.startCapture(with: captureDescriptor)
//        } catch {
//            print(error)
//        }
    }
    
    private func onDebugStop(_ captureManager: MTLCaptureManager = .shared()) {
//        if captureManager.isCapturing {
//            captureManager.stopCapture()
//        }
    }
    
    // MARK: - Encode result processing
    
    func cacheCollectionAsGrid(from result: EncodeResult) {
        switch result.collection {
        case .built(let collection):
            cacheCollectionAsGrid(
                collection: collection,
                sourceURL: result.sourceURL
            )
            
        case .notBuilt:
            break
        }
    }
    
    @discardableResult
    func cacheCollectionAsGrid(
        collection: GlyphCollection,
        sourceURL: URL
    ) -> CodeGrid {
        builder
            .createGrid(around: collection)
            .withSourcePath(sourceURL)
            .withFileName(sourceURL.lastPathComponent)
            .applyName()
            .applying { grid in
                let parentUrl = sourceURL.deletingLastPathComponent()
                guard let parentGroup = state.directoryGroups[parentUrl] else {
                    fatalError("YOU WERE THE CHOSEN ONE: \(parentUrl)")
                }
                
                parentGroup.addChildGrid(grid)
                gridCache.insertGrid(grid)
                hoverController.attachPickingStream(to: grid)
                grid.updateBackground()
                
                colorizeIfEnabled(grid)
            }
    }
    
    func colorizeIfEnabled(_ grid: CodeGrid) {
        if colorizeOnLoad {
            // Colorizing can complete concurrently for now, it's pretty quick and won't hold up
            // the general render, since colorizing huge files takes forever
            WorkerPool.shared.nextConcurrentWorker().async {
                try? GlobalInstances.colorizer.runColorizer(
                    colorizerQuery: .highlights,
                    on: grid
                )
            }
        }
    }
}

// MARK: - Code group

private extension RenderPlan {
    func cacheCodeGroups(for directories: [URL]) {
        // Double pass; build out groups...
        for directoryURL in directories {
            let grid = gridCache
                .setCache(directoryURL)
                .withSourcePath(directoryURL)
                .withFileName(directoryURL.fileName)
                .applyName()
                .removeBackground()
            
            let group = CodeGridGroup(globalRootGrid: grid)
            state.directoryGroups[directoryURL] = group
        }
        
        // .. then set up their relationships. I like loops.
        for directoryURL in directories {
            guard let group = group(for: directoryURL),
                  let parent = parentGroup(for: directoryURL)
            else {
                continue
            }
            guard group.globalRootGrid.parent == nil else {
                print("""
                Skip attach:
                \(group.globalRootGrid.fileName) -> to ->
                \(parent.globalRootGrid.fileName)"
                """)
                continue
            }
            parent.addChildGroup(group)
        }
    }
    
    func group(for url: URL) -> CodeGridGroup? {
        state.directoryGroups[url]
    }
    
    func parentGroup(for url: URL) -> CodeGridGroup? {
        state.directoryGroups[url.deletingLastPathComponent()]
    }
}

class WatchWrap {
    static let stopwatch = Stopwatch(running: false)
    
    static func startTimer(_ name: String) {
        print("[* StopWatch *] Starting \(name)")
        stopwatch.start()
        
    }
    static func stopTimer(_ name: String) {
        defer { stopwatch.reset() }
        stopwatch.stop()
        let time = Self.stopwatch.elapsedTimeString()
        print("[* Stopwatch *] Time for \(name): \(time)")
    }
}
