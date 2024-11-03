//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/18/24.
//

import SwiftUI
import Combine
import BitHandling
import MetalLink

public class UserTextEditingRenderer: ObservableObject, MetalLinkReader {
    public let link: MetalLink
    public let renderer: DataStreamRenderer
    public let builder: CodeGridGlyphCollectionBuilder
    public let holder: UserTextEditingStateHolder
    private var bag = Set<AnyCancellable>()
    
    private var currentGrid: CodeGrid?
    
    init(
        link: MetalLink,
        holder: UserTextEditingStateHolder,
        builder: CodeGridGlyphCollectionBuilder
    ) {
        self.link = link
        self.builder = builder
        self.holder = holder
        self.renderer = DataStreamRenderer(
            link: link,
            atlas: GlobalInstances.defaultAtlas,
            compute: GlobalInstances.gridStore.sharedConvert,
            dataStream: holder
                .$watchData
                .compactMap { $0 }
                .removeDuplicates()
                .eraseToAnyPublisher(),
            name: "SGTestDataRenderer"
        )
        
        bind()
    }
    
    public func bind() {
        renderer
            .collectionStream
            .sink(receiveValue: onCollectionUpdated(_:))
            .store(in: &bag)
        
        holder
            .$userSelectedGrid
            .compactMap { $0 }
            .sink(receiveValue: {
                self.currentGrid = $0
            })
            .store(in: &bag)
    }
    
    private func onCollectionUpdated(_ collection: GlyphCollection) {
        guard
            let currentGrid,
            let parent = currentGrid.parent
        else {
            print("Missing state in edit renderer")
            return
        }
        
        currentGrid.detatchPicking()
        
        let nextGrid = self.builder
            .createGrid(around: collection)
            .applying {
                $0.copyDisplayState(from: currentGrid)
                $0.attachPicking()
            }
        
        parent.remove(child: currentGrid.rootNode)
        self.currentGrid = nextGrid
        parent.add(child: nextGrid.rootNode)
    }
}

private extension CodeGrid {
    func attachPicking() {
        GlobalInstances.gridStore
            .nodeHoverController
            .attachPickingStream(to: self)
    }

    func detatchPicking() {
        GlobalInstances.gridStore
            .nodeHoverController
            .detachPickingStream(from: self)
    }
}
