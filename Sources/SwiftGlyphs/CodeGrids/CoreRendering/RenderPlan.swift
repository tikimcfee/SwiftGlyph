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
    var colorizeOnLoad: Bool { GlobalLiveConfig.store.preference.colorizeOnOpen }
    
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
    lazy var watch = WatchWrap(name: rootPath.lastPathComponent)
    
    init(
        mode: Mode,
        rootPath: URL,
        editor: WorldGridEditor,
        focus: WorldGridFocusController
    ) {
        self.mode = mode
        self.rootPath = rootPath.resolvingSymlinksInPath()
        self.editor = editor
        self.focus = focus
    }
    
    func startRender(
        _ onComplete: @escaping (RenderPlan) -> Void = { _ in }
    ) {
        statusObject.resetProgress()
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.title = "Your computer is about to explode <3"
            $0.isActive = true
        }
        
        WorkerPool.shared.nextConcurrentWorker().async {
            self.onStart(onComplete)
        }
    }
    
    func postFinish() {
        statusObject.update {
            $0.title = "Render complete!"
            $0.currentValue = $0.totalValue
            $0.isActive = false
        }
    }
    
    private func onStart(
        _ onComplete: @escaping (RenderPlan) -> Void
    ) {
        renderTaskForMode(onComplete)
    }
}

private extension RenderPlan {
    func renderTaskForMode(
        _ onComplete: @escaping (RenderPlan) -> Void
    ) {
        switch mode {
        case .cacheAndLayoutStream:
            computeAllTheGrids_stream({ _ in
                self.bag = .init()
                self.postFinish()
                onComplete(self)
            })
            
        case .cacheAndLayout:
            watch.start(.cache)
            cacheGrids_V2()
            watch.stop(.cache)
            
            watch.start(.layout)
            doGridLayout()
            watch.stop(.layout)
            
            postFinish()
            onComplete(self)

        case .cacheOnly:
            watch.start(.cache)
            cacheGrids_V2()
            watch.stop(.cache)
            
            postFinish()
            onComplete(self)
            
        case .layoutOnly:
            watch.start(.layout)
            doGridLayout()
            watch.stop(.layout)
            
            postFinish()
            onComplete(self)
        }
    }
    
    func doGridLayout() {        
        statusObject.update {
            $0.totalValue += 1
            $0.title = "Starting layout..."
        }
        rootGroup.applyAllConstraints(myDepth: 0)
        
        rootGroup.addLines(root: rootGroup.asNode)
        rootGroup.addAllWalls()
        
        let layoutTime = watch.stopwatch.elapsedTimeString()
        statusObject.update {
            $0.currentValue += 1
            $0.totalValue += 1
            $0.title = "Layout complete: \(layoutTime)"
        }
    }
}

private extension RenderPlan {
    func cacheGrids_V2() {
        computeAllTheGrids()
    }
    
    func computeAllTheGrids() {
        // Gather all the files and directories at once.
        // Threads. Heh.
        let (allDirectoryURLs, allFileURLs) = collectFilesFromRoot()
        
        // Check we have something to render
        guard !allFileURLs.isEmpty || !allDirectoryURLs.isEmpty else {
            statusObject.update {
                $0.currentValue += 1
                $0.title = "Didn't find any supported files to render."
            }
            return
        }
        
        statusObject.update {
            $0.title = "Found \(allFileURLs.count) files to render."
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
                            $0.title = "File mapped to data: \(string)"
                            
                        case .layoutEncoded(let string):
                            $0.title = "Atlas layout encoded: \(string)"
                            
                        case .copyEncoded(let string):
                            $0.title = "Preparing glyph copy: \(string)"
                            
                        case .collectionReady(let string):
                            $0.title = "Collection made ready: \(string)"
                        }
                    }
                }
            )

            for collectionResult in allMappedAtlasResults {
                cacheCollectionAsGrid(from: collectionResult)
                statusObject.update {
                    $0.title = "Completed grid creation: \(collectionResult.sourceURL.lastPathComponent)"
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
        watch.start(.cache)
        let (allDirectoryURLs, allFileURLs) = collectFilesFromRoot()
        
        // Check we have something to render
        guard !allFileURLs.isEmpty || !allDirectoryURLs.isEmpty else {
            statusObject.update {
                $0.currentValue += 1
                $0.title = "Didn't find any supported files to render."
            }
            return
        }
        
        statusObject.update {
            $0.title = "Found \(allFileURLs.count) files to render."
            $0.totalValue += Double(allFileURLs.count)
        }
        
        // Setup all the directory relationships first
        cacheCodeGroups(for: allDirectoryURLs)
                
        statusObject.update {
            $0.title = "Kicking off concurrent render..."
        }
        
        let cacheLock = LockWrapper()
        DispatchQueue.concurrentPerform(iterations: allFileURLs.count) { index in
            let renderPath = allFileURLs[index]
            statusObject.update {
                $0.title = "Started rendering: \(renderPath.lastPathComponent)"
            }
            
            let result = compute.executeManyWithAtlas_Conc(
                in: renderPath,
                atlas: builder.atlas
            )
            
            if let result {
                cacheLock.writeLock()
                let grid = cacheCollectionAsGrid(from: result)
                cacheLock.unlock()
                
                if let grid {
                    colorizeIfEnabled(grid)
                }
                
                statusObject.update {
                    $0.title = "Finished rendering: \(renderPath.lastPathComponent)"
                    $0.currentValue += 1
                }
            } else {
                statusObject.update {
                    $0.title = "Failed to create EncodeResult for: \(renderPath.lastPathComponent)"
                    $0.currentValue += 1
                }
            }
        }
        let cacheTime = watch.stopwatch.elapsedTimeString()
        watch.stop(.cache)
        
        statusObject.update {
            $0.title = "Rendering complete: \(cacheTime)"
        }
        
        watch.start(.layout)
        doGridLayout()
        watch.stop(.layout)
        
        onComplete(self)
    }
    
    func collectFilesFromRoot() -> (
        directories: [URL],
        files: [URL]
    ) {
        // Gather all the files and directories at once.
        // Threads. Heh.
        var allFileURLs = [URL]()
        var allDirectoryURLs = [URL]()
        let rootIsFile = !rootPath.isDirectory
        
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
            let paths = FileBrowser.recursivePaths(rootPath)
            for path in paths {
                if path.isDirectory {
                    allDirectoryURLs.append(path)
                } else if path.isSupportedFileType {
                    allFileURLs.append(path)
                }
            }
        }
        
        return (
            directories: allDirectoryURLs,
            files: allFileURLs
        )
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
    
    @discardableResult
    func cacheCollectionAsGrid(
        from result: EncodeResult
    ) -> CodeGrid? {
        switch result.collection {
        case .built(let collection):
            cacheCollectionAsGrid(
                collection: collection,
                sourceURL: result.sourceURL
            )
            
        case .notBuilt:
            nil
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
            }
    }
    
    func colorizeIfEnabled(_ grid: CodeGrid) {
        if
            colorizeOnLoad,
            grid.sourcePath?.isDirectory == false
        {
            // Colorizing can complete concurrently for now, it's pretty quick and won't hold up
            // the general render, since colorizing huge files takes forever
            WorkerPool.shared.nextConcurrentWorker().async {
//                self.statusObject.update {
//                    $0.title = "Starting coloring: \(grid.id)"
//                    $0.totalValue += 1
//                }
                
                try? GlobalInstances.colorizer.runColorizer(
                    colorizerQuery: .highlights,
                    on: grid
                )
                
//                self.statusObject.update {
//                    $0.title = "Coloring finished: \(grid.id)"
//                    $0.currentValue += 1
//                }
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
    let stopwatch = Stopwatch(running: false)
    let name: String
    
    enum Stage: String {
        case cache
        case layout
    }
    
    init(name: String) {
        self.name = name
    }
    
    func start(_ stage: Stage) {
        print("[* StopWatch *]\n\(name)\n Starting \(stage)")
        stopwatch.start()
        
    }
    
    func stop(_ stage: Stage) {
        defer { stopwatch.reset() }
        stopwatch.stop()
        let time = stopwatch.elapsedTimeString()
        print("[* StopWatch *]\n\(name)\n Stopping \(stage): \(time)")
    }
}
