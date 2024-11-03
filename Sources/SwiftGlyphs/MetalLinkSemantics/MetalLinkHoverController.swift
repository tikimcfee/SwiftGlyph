//
//  MetalLinkSemantics.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/30/22.
//

import Combine
import SwiftUI
import MetalLink
import MetalLinkHeaders
import BitHandling

public typealias GlyphConstants = InstancedConstants
public typealias ConstantsPointer = UnsafeMutablePointer<GlyphConstants>
public typealias UpdateConstants = (GlyphNode, inout Bool) throws -> Void

public class MetalLinkHoverController: ObservableObject {
    
    public let link: MetalLink
    private var bag = Set<AnyCancellable>()
    
    @Published public var lastGlyphEvent: NodePickingState.Event = .initial
    @Published public var lastGridEvent: GridPickingState.Event = .initial
    
    public lazy var sharedGridEvent = $lastGridEvent.share().eraseToAnyPublisher()
    public lazy var sharedGlyphEvent = $lastGlyphEvent.share().eraseToAnyPublisher()
    
    private var trackedGrids = ConcurrentDictionary<CodeGrid.ID, CodeGrid>()
    private let panController = PanController()
    
    public init(link: MetalLink) {
        self.link = link
        setupPickingHoverStream()
        setupControlsStream()
    }
    
    public func contains(_ grid: CodeGrid) -> Bool {
        trackedGrids.contains(grid.id)
    }
    
    public func attachPickingStream(to newGrid: CodeGrid) {
        guard trackedGrids[newGrid.id] == nil else { return }
        trackedGrids[newGrid.id] = newGrid
    }
    
    public func detachPickingStream(from grid: CodeGrid) {
        trackedGrids[grid.id] = nil
    }
}

private extension MetalLinkHoverController {
    func setupControlsStream() {
        var lastEvent: PanEvent?
        let movements = link.input.sharedMouse.map {
            PanEvent(state: .changed, currentLocation: $0.locationInWindow.asSimd)
        }
        let panStart = link.input.sharedMouseDown.map {
            PanEvent(state: .began, currentLocation: $0.locationInWindow.asSimd)
        }
        let panEnd = link.input.sharedMouseUp.map {
            PanEvent(state: .ended, currentLocation: $0.locationInWindow.asSimd)
        }
        let cameraChangeStream = panController.camera.positionStream
            .merge(with: panController.camera.rotationSream)
            .compactMap { _ in lastEvent }
            .prepend(.newEmpty)
        
        panStart
            .merge(with: movements, panEnd)
            .combineLatest(cameraChangeStream.map { _ in () } )
            .map { $0.0 }
            .removeDuplicates()
            .sink { event in
                guard let grid = self.lastGridEvent.lastState?.targetGrid
                else { return }
                
                lastEvent = event
                self.panController.pan(event, on: grid)
            }
            .store(in: &bag)
    }
    
    func setupPickingHoverStream() {
        link.glyphPickingTexture.sharedPickingHover.sink { glyphID in
            self.doGlyphPicking(glyphID: glyphID)
        }.store(in: &bag)
        
        link.gridPickingTexture.sharedPickingHover.sink { gridID in
            self.doGridPicking(gridID: gridID.id)
        }.store(in: &bag)
    }
    
    func doGlyphPicking(glyphID: PickingTextureOutputWrapper) {
        guard let grid = lastGridEvent.newState?.targetGrid else { return }
        
        lastGlyphEvent = Self.computeNodePickingEvent(
            in: grid,
            glyphID: glyphID,
            lastGlyphEvent: lastGlyphEvent
        )
    }
    
    func doGridPicking(gridID: InstanceIDType) {
        lastGridEvent = Self.computeGridPickingEvent(
            gridID: gridID,
            lastGridEvent: lastGridEvent,
            allGrids: trackedGrids
        )
    }
}

// MARK: - Grid picking

private extension MetalLinkHoverController {
    static func computeGridPickingEvent(
        gridID: InstanceIDType,
        lastGridEvent: GridPickingState.Event,
        allGrids: ConcurrentDictionary<CodeGrid.ID, CodeGrid>
    ) -> GridPickingState.Event {
        for grid in allGrids.values {
            // Find matching grid
            guard grid.backgroundID == gridID
            else { continue }
            
            // Create and update new state
            let newState = GridPickingState(targetGrid: grid)
            
            // Return new event
            if let oldState = lastGridEvent.newState,
               oldState.targetGrid.backgroundID == gridID
            {
                return .matchesLast(last: oldState, new: newState)
            } else {
                print("Hovering \(grid.fileName)")
                return .foundNew(last: lastGridEvent.newState, new: newState)
            }
        }
        
        return .useLast(last: lastGridEvent.newState)
//        return .notFound
    }
}

// MARK: - Glyph picking

private extension MetalLinkHoverController {
    static func computeNodePickingEvent(
        in targetGrid: CodeGrid,
        glyphID: PickingTextureOutputWrapper,
        lastGlyphEvent: NodePickingState.Event
    ) -> NodePickingState.Event {
        guard let node = targetGrid.rootNode.createWrappedNode(for: glyphID) else {
            return .useLast(last: lastGlyphEvent.latestState)
        }
        
        // Create a new state to test against
        let newState = NodePickingState(
            targetGrid: targetGrid,
            nodeID: glyphID.id,
            node: node
        )

        // Skip matching syntax ids; send last state to allow action on last node
        
        if let oldState = lastGlyphEvent.latestState,
//           oldState.parserSyntaxID == newState.parserSyntaxID
           oldState.nodeID == newState.nodeID
        {
            return .matchesLast(last: oldState, new: newState)
        } else {
            return .foundNew(last: lastGlyphEvent.latestState, new: newState)
        }
    }
}
