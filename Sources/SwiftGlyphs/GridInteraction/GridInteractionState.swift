//
//  LinkLanguageServer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/16/22.
//

import Foundation
import Combine
import MetalLink
import SwiftUI
import Collections

@Observable
public class GridInteractionState {
    var bag = Set<AnyCancellable>()
    
    public var bookmarkedGrids: OrderedSet<CodeGrid> = .init()
    
    public let hoverController: MetalLinkHoverController
    public let input: DefaultInputReceiver
    
    public init(
        hoverController: MetalLinkHoverController,
        input: DefaultInputReceiver
    ) {
        self.hoverController = hoverController
        self.input = input
    }
    
    public func setupStreams() {
        let glyphStream = hoverController.sharedGlyphEvent
//        let gridStream = hoverController.sharedGridEvent
        
        glyphStream
            .sink { glyph in
                self.handleNodeEvent(glyph)
            }
            .store(in: &bag)
    }
}

private extension GridInteractionState {
    func handleNodeEvent(
        _ glyphEvent: NodePickingState.Event
    ) {
        switch glyphEvent {
        case let (.foundNew(.none, newGlyph)):
            focusGlyphState(newGlyph)
            
        case let (.foundNew(.some(lastGlyph), newGlyph)):
            defocusGlyphState(lastGlyph)
            focusGlyphState(newGlyph)
            
        default:
            break
        }
    }
    
    func focusGlyphState(_ nodeState: NodePickingState) {
        LFloat4(0.0, 0.9, 0.0, 0.0)
            .setAddedColor(on: &nodeState.node.instanceConstants)
    }
    
    func defocusGlyphState(_ nodeState: NodePickingState) {
        LFloat4(0.0, 0.0, 0.0, 0.0)
            .setAddedColor(on: &nodeState.node.instanceConstants)
    }
    
    private func updateGlyphState(_ pickingState: NodePickingState, _ action: (GlyphNode) -> Void) {
        guard let pickedNodeSyntaxID = pickingState.parserSyntaxID
        else { return }
        
        pickingState
            .targetGrid
            .updateAssociatedNodes(
                pickedNodeSyntaxID
            ) { node, _ in
                action(node)
            }
    }
}

public extension Array where Element: CodeGrid {
    enum Selection {
        case addedToSet, removedFromSet
    }
    
    @discardableResult
    mutating func toggle(_ toggled: Element) -> Selection {
        let index = firstIndex(where: { $0.id == toggled.id })
        if let index {
            remove(at: index)
            return .removedFromSet
        } else {
            append(toggled)
            return .addedToSet
        }
    }
}
