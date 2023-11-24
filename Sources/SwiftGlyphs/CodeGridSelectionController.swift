//
//  CodeGridSelectionController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/30/22.
//

import Foundation
import MetalLink
import BitHandling
import SwiftSyntax

public class GlobalNodeController {
    public func focus(_ node: GlyphNode) {
        node.instanceConstants?.addedColor += LFloat4(0.2, 0.2, 0.2, 1)
    }
    
    public func unfocus(_ node: GlyphNode) {
        node.instanceConstants?.addedColor -= LFloat4(0.2, 0.2, 0.2, 1)
    }
}

public class CodeGridSelectionController: ObservableObject {
    public struct State {
        var trackedGridSelections = [CodeGrid: Set<SyntaxIdentifier>]()
        var trackedMapSelections = Set<SyntaxIdentifier>()
        
        func isSelected(_ id: SyntaxIdentifier) -> Bool {
            trackedMapSelections.contains(id)
            || trackedGridSelections.values.contains(where: { $0.contains(id) })
        }
    }
    
    @Published public  var state: State = State()
    public var tokenCache: CodeGridTokenCache
    public var nodeController: GlobalNodeController = GlobalNodeController()
    
    public init(
        tokenCache: CodeGridTokenCache
    ) {
        self.tokenCache = tokenCache
    }
    
    @discardableResult
    public func selected(
        id: SyntaxIdentifier,
        in grid: CodeGrid
    ) -> Bounds {
        // Update set first
        var selectionSet = state.trackedGridSelections[grid, default: []]
        let isSelectedAfterToggle = selectionSet.toggle(id) == .addedToSet
        state.trackedGridSelections[grid] = selectionSet
        
        let update = isSelectedAfterToggle
            ? nodeController.focus
            : nodeController.unfocus
        

        var totalBounds = Bounds.forBaseComputing
        grid.semanticInfoMap
            .walkFlattened(from: id, in: tokenCache) { info, nodes in
                for node in nodes {
                    totalBounds.union(with: node.worldBounds)
                    update(node)
                }
            }
        return totalBounds
    }
    
    public func isSelected(_ id: SyntaxIdentifier) -> Bool {
        return state.isSelected(id)
    }
}
