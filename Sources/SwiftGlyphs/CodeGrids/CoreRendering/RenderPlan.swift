//
//  RenderPlan.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/21/22.
//

import SwiftSyntax
import Foundation
import OrderedCollections
import MetalLink
import BitHandling

struct RenderPlan {
    let rootPath: URL
    let queue: DispatchQueue
    
    var statusObject: AppStatus { GlobalInstances.appStatus }
    var compute: ConvertCompute { GlobalInstances.gridStore.sharedConvert }
    
    let builder: CodeGridGlyphCollectionBuilder
    
    let editor: WorldGridEditor
    let focus: WorldGridFocusController
    let hoverController: MetalLinkHoverController
    
    let targetParent = MetalLinkNode()
    
    class State {
        /// Maps the file or directory URL to its contained.
        /// It's either the parent, or one of its children.
//        var directoryGroups = [URL: CodeGridGroup]()
//        
        var directoryGroups = ConcurrentDictionary<URL, CodeGridGroup>()
    }
    var state = State()

    
    let mode: Mode
    enum Mode {
        case cacheOnly
        case layoutOnly
        case cacheAndLayout
    }
    
    func startRender(
        _ onComplete: @escaping (RenderPlan) -> Void = { _ in }
    ) {
        queue.async {
            statusObject.resetProgress()
            
            WatchWrap.startTimer("\(rootPath.fileName)")
            renderTaskForMode()
            WatchWrap.stopTimer("\(rootPath.fileName)")
            
            statusObject.update {
                $0.message = "Render complete!"
                $0.currentValue = statusObject.progress.totalValue
            }
            
            onComplete(self)
        }
    }
    
    private var renderTaskForMode: () -> Void {
        switch mode {
        case .cacheAndLayout:
            return {
                cacheGrids_V2()
                doGridLayout()
                
//                GlobalInstances.defaultAtlas.save()
            }
        case .cacheOnly:
            return {
                cacheGrids_V2()
            }
        case .layoutOnly:
            return {
                doGridLayout()
            }
        }
    }
}

private extension RenderPlan {
    func doGridLayout() {
        justShowMeCodePlease()
    }
    
    func justShowMeCodePlease() {
        guard rootPath.isDirectory else { return }
        
//        var count = 0
//        var last: CodeGrid?
//        for grid in builder.sharedGridCache.cachedGrids.values {
//            if grid.sourcePath?.isFileURL == true,
//               let parent = grid.parent,
//               grid.parent != targetParent
//            {
//                parent.remove(child: grid.rootNode)
//            }
//            
//            if let last {
//                grid.setTrailing(last.trailing)
//                    .setTop(last.top)
//                    .setFront(last.back - 32)
//                targetParent.add(child: grid.rootNode)
//            } else {
//                targetParent.add(child: grid.rootNode)
//            }
//            
//            last = grid
//            count += 1
//        }
//        print("added: \(count)")
        
        state.directoryGroups[rootPath]?.applyAllConstraints()
        state.directoryGroups[rootPath]?.addLines(targetParent)
    }
}

private extension RenderPlan {
    func cacheGrids_V2() {
        computeAllTheGrids()
    }
    
    func computeAllTheGrids() {
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Your GPU is about to explode <3"
        }
        
        // Gather all the files and directories at once.
        // Threads. Heh.
        var allFileURLs = [URL]()
        var allDirectoryURLs = [URL]()
        let rootIsFile = rootPath.isSupportedFileType
        
        if rootIsFile {
            // Render the root file as well
            allFileURLs.append(rootPath)
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
                    } else if $0.isSupportedFileType {
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
        
        // First render all directories...
        for directoryURL in allDirectoryURLs {
            launchDirectoryGridBuild(directoryURL)
        }
        
        // .. then set up their relationships. I like loops.
        for directoryURL in allDirectoryURLs {
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
        
        if !rootIsFile {
            // Now look for root group. Big problems if we miss it.
            guard let rootGroup = state.directoryGroups[rootPath] else {
                fatalError("But where did the root go")
            }
            targetParent.add(child: rootGroup.globalRootGrid.rootNode)
        }
        
        // Then ask kindly of the gpu to go 'ham'
        
        do {
            let allMappedAtlasResults = try compute.executeManyWithAtlas(
                sources: allFileURLs,
                atlas: builder.atlas
            )
            for collectionResult in allMappedAtlasResults {
                doGridStore(from: collectionResult)
            }
        } catch {
            fatalError("Crash for now, my man: \(error)")
        }
        
        func doGridStore(from result: EncodeResult) {
            switch result.collection {
            case .built(let collection):
                CodeGrid(
                    rootNode: collection,
                    tokenCache: builder.sharedTokenCache
                )
                .withSourcePath(result.sourceURL)
                .withFileName(result.sourceURL.lastPathComponent)
                .applyName()
                .applying {
                    if result.sourceURL == rootPath {
                        print("<Found source grid url>")
                        targetParent.add(child: $0.rootNode)
                    } else {
                        guard let parentGroup = state.directoryGroups[
                            result
                                .sourceURL
                                .deletingLastPathComponent()
                        ] else {
                            fatalError("YOU WERE THE CHOSEN ONE")
                        }
                        
                        parentGroup.addChildGrid($0)
                        builder.sharedGridCache.insertGrid($0)
                        hoverController.attachPickingStream(to: $0)
                        $0.updateBackground()
                    }
                }
                
            case .notBuilt:
                break
            }
        }
    }
    
    func cacheGrids_V1() {
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Starting grid cache..."
        }
        
        let dispatchGroup = DispatchGroup()
        
        guard rootPath.isDirectory else {
            let rootGrid = launchFileGridBuildSync(rootPath)
            targetParent.add(child: rootGrid.rootNode)
            return
        }
        
        let rootGrid = builder.sharedGridCache
            .setCache(rootPath)
            .withSourcePath(rootPath)
            .withFileName(rootPath.fileName)
            .applyName()
        
        rootGrid.removeBackground()
        
        let rootGroup = CodeGridGroup(globalRootGrid: rootGrid)
        state.directoryGroups[rootPath] = rootGroup
        targetParent.add(child: rootGrid.rootNode)
        
        FileBrowser.recursivePaths(rootPath).forEach { childPath in
            if FileBrowser.isSupportedFileType(childPath) {
                launchFileGridBuild(dispatchGroup, childPath)
            } else if childPath.isDirectory {
                launchDirectoryGridBuild(childPath)
            } else {
                print("Skipping file: \(childPath.fileName)")
            }
        }
        dispatchGroup.wait()
        
        FileBrowser.recursivePaths(rootPath).forEach { childPath in
            if FileBrowser.isSupportedFileType(childPath) {
                let grid = builder
                    .sharedGridCache
                    .get(childPath)!
                
                let group = state
                    .directoryGroups[childPath.deletingLastPathComponent()]!
                
                group.addChildGrid(grid)
            } else if childPath.isDirectory,
                   let group = group(for: childPath),
                   let parent = parentGroup(for: childPath) {
                guard group.globalRootGrid.parent == nil else {
                    print("Skip attach \(group.globalRootGrid.fileName) to \(parent.globalRootGrid.fileName)")
                    return
                }
                parent.addChildGroup(group)
            }
        }
    }
    
    func group(for url: URL) -> CodeGridGroup? {
        state.directoryGroups[url]
    }
    
    func parentGroup(for url: URL) -> CodeGridGroup? {
        state.directoryGroups[url.deletingLastPathComponent()]
    }
    
    func launchDirectoryGridBuild(
        _ childPath: URL
    ) {
        let grid = builder.sharedGridCache
            .setCache(childPath)
            .withSourcePath(childPath)
            .withFileName(childPath.fileName)
            .applyName()
            .removeBackground()
        
        let group = CodeGridGroup(globalRootGrid: grid)
        state.directoryGroups[childPath] = group
    }
    
    func launchFileGridBuild(
        _ dispatchGroup: DispatchGroup,
        _ childPath: URL
    ) {
        var worker: DispatchQueue { WorkerPool.shared.nextWorker() }
        
        dispatchGroup.enter()
        statusObject.update {
            $0.totalValue += 1
            $0.detail = "File: \(childPath.lastPathComponent)"
        }
        
        worker.async {
            let grid = builder
                .createConsumerForNewGrid()
                .consume(url: childPath)
                .withFileName(childPath.lastPathComponent)
                .withSourcePath(childPath)
                .applyName()
            
            builder.sharedGridCache.cachedFiles[childPath] = grid.id
            hoverController.attachPickingStream(to: grid)
            
            statusObject.update {
                $0.currentValue += 1
                $0.detail = "File Complete: \(childPath.lastPathComponent)"
            }
            dispatchGroup.leave()
        }
    }
    
    @discardableResult
    func launchFileGridBuildSync(
        _ childPath: URL
    ) -> CodeGrid {
        var worker: DispatchQueue { WorkerPool.shared.nextWorker() }
        
        statusObject.update {
            $0.totalValue += 1
            $0.detail = "File: \(childPath.lastPathComponent)"
        }
        
        let codeGrid: CodeGrid = worker.sync {
            let grid = builder
                .createConsumerForNewGrid()
                .consume(url: childPath)
                .withFileName(childPath.lastPathComponent)
                .withSourcePath(childPath)
                .applyName()
            
            builder.sharedGridCache.cachedFiles[childPath] = grid.id
            hoverController.attachPickingStream(to: grid)
            
            statusObject.update {
                $0.currentValue += 1
                $0.detail = "File Complete: \(childPath.lastPathComponent)"
            }
            
            return grid
        }
        return codeGrid
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

// MARK: - Focus Style

extension LFloat3 {
    var magnitude: Float {
        sqrt(x * x + y * y + z * z)
    }
    
    var normalized: LFloat3 {
        let magnitude = magnitude
        return magnitude == 0
            ? .zero
            : self / magnitude
    }
    
    mutating func normalize() -> LFloat3 {
        self = self / magnitude
        return self
    }
}
