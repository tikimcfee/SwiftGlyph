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

class RenderPlan {
    var statusObject: AppStatus { GlobalInstances.appStatus }
    var compute: ConvertCompute { GlobalInstances.gridStore.sharedConvert }
    let targetParent = MetalLinkNode()
    
    class State {
        var directoryGroups = [URL: CodeGridGroup]()
    }
    let state = State()
    
    enum Mode {
        case cacheOnly
        case layoutOnly
        case cacheAndLayout
    }
    let mode: Mode
    
    let rootPath: URL
    let builder: CodeGridGlyphCollectionBuilder
    let editor: WorldGridEditor
    let focus: WorldGridFocusController
    let hoverController: MetalLinkHoverController
    
    init(
        mode: Mode,
        rootPath: URL,
        builder: CodeGridGlyphCollectionBuilder,
        editor: WorldGridEditor,
        focus: WorldGridFocusController,
        hoverController: MetalLinkHoverController
    ) {
        self.mode = mode
        self.rootPath = rootPath
        self.builder = builder
        self.editor = editor
        self.focus = focus
        self.hoverController = hoverController
    }
    
    func startRender(
        _ onComplete: @escaping (RenderPlan) -> Void = { _ in }
    ) {
        WorkerPool.shared.nextConcurrentWorker().async {
            self.onStart()
            onComplete(self)
        }
    }
    
    private func onStart() {
        statusObject.resetProgress()
        
        statusObject.update {
            $0.totalValue += 1 // pretend there's at least one unfinished task
            $0.message = "Your computer is about to explode <3"
        }
        
        WatchWrap.startTimer("\(rootPath.fileName)")
        renderTaskForMode()
        WatchWrap.stopTimer("\(rootPath.fileName)")
        
        statusObject.update {
            $0.message = "Render complete!"
            $0.currentValue = $0.totalValue
        }
    }
}

private extension RenderPlan {
    func renderTaskForMode() {
        switch mode {
        case .cacheAndLayout:
            cacheGrids_V2()
            doGridLayout()

        case .cacheOnly:
            cacheGrids_V2()
            
        case .layoutOnly:
            doGridLayout()
        }
    }
    
    func doGridLayout() {
        guard rootPath.isDirectory else { return }
        
        statusObject.update {
            $0.totalValue += 1
            $0.message = "Starting layout.. this is the slow part."
        }
        state.directoryGroups[rootPath]?.applyAllConstraints()
        
        statusObject.update {
            $0.currentValue += 1
            $0.totalValue += 1
            $0.message = "Jump in the line..."
        }
        state.directoryGroups[rootPath]?.addLines(targetParent)
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
        
        statusObject.update {
            $0.message = "Found \(allFileURLs.count) files to render."
        }
        
        // Setup all the directory relationships first
        cacheCodeGroups(for: allDirectoryURLs)
        
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

            let group = DispatchGroup()
            for collectionResult in allMappedAtlasResults {
                group.enter()
                WorkerPool.shared.nextWorker().async {
                    self.cacheCollectionAsGrid(from: collectionResult)
                    self.statusObject.update {
                        $0.message = "Completed grid creation: \(collectionResult.sourceURL.lastPathComponent)"
                        $0.currentValue += 1
                    }
                    group.leave()
                }
            }
            group.wait()
            
        } catch {
            fatalError("Crash for now, my man: \(error)")
        }
    }
    
    // MARK: - Encode result processing
    
    func cacheCollectionAsGrid(from result: EncodeResult) {
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

// MARK: - Code group

private extension RenderPlan {
    func cacheCodeGroups(for directories: [URL]) {
        // Double pass; build out groups...
        for directoryURL in directories {
            let grid = builder.sharedGridCache
                .setCache(directoryURL)
                .withSourcePath(directoryURL)
                .withFileName(directoryURL.fileName)
                .applyName()
                .removeBackground()
            
            let group = CodeGridGroup(globalRootGrid: grid)
            grid.rootNode.pausedInvalidate = true
            
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
