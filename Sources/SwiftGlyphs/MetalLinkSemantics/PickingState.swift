//
//  PickingState.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/18/22.
//

import Foundation
import SwiftSyntax
import MetalLink

public struct NodePickingState {
    public let targetGrid: CodeGrid
    public let nodeID: InstanceIDType
    public let node: GlyphNode
    
    public var nodeBufferIndex: Int? { node.instanceBufferIndex }
    public var nodeSyntaxID: NodeSyntaxID? { node.meta.syntaxID }
    
    public var constantsPointer: ConstantsPointer {
        return targetGrid.rootNode.instanceState.rawPointer
    }
    
    public var parserSyntaxID: SyntaxIdentifier? {
        guard let id = nodeSyntaxID else { return nil }
        return targetGrid.semanticInfoMap.syntaxIDLookupByNodeId[id]
    }
    
    public enum Event {
        case initial
        case useLast(last: NodePickingState?)
        case matchesLast(last: NodePickingState, new: NodePickingState)
        case foundNew(last: NodePickingState?, new: NodePickingState)
        
        public var latestState: NodePickingState? {
            switch self {
            case let .useLast(.some(state)),
                let .matchesLast(_, state),
                let .foundNew(_, state):
                return state
            default:
                return nil
            }
        }
    }
}

public struct GridPickingState {
    public let targetGrid: CodeGrid
    
    public enum Event {
        case initial
        case useLast(last: GridPickingState?)
        case matchesLast(last: GridPickingState, new: GridPickingState)
        case foundNew(last: GridPickingState?, new: GridPickingState)
        
        public var maybeLasteState: GridPickingState? {
            switch self {
            case let .useLast(.some(last)),
                let .matchesLast(last, _),
                let .foundNew(.some(last), _):
                return last
            default:
                return nil
            }
        }
        
        public var latestState: GridPickingState? {
            switch self {
            case let .useLast(.some(state)),
                let .matchesLast(_, state),
                let .foundNew(_, state):
                return state
            default:
                return nil
            }
        }
    }
}
