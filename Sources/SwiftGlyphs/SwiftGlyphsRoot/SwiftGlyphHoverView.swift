//
//
//  Created on 12/17/23.
//

#if os(iOS)
import ARKit
#endif
import SwiftUI
import MetalLink
import BitHandling

public struct SwiftGlyphHoverView: View, MetalLinkReader {
    public let link: MetalLink
    
    @State private var currentHoveredGrid: GridPickingState.Event?
    @State private var currentHoveredNode: NodePickingState.Event?
    
    @State private var mousePosition: LFloat2?
    @State private var tapPosition: LFloat2?
    
    #if os(macOS)
    @State private var modifiers = OSEvent.ModifierFlags()
    #endif
    
    @State private var autoJump = false
    
    public init(link: MetalLink) {
        self.link = link
    }
    
    // We assume we take up the same size as the parent
    public var body: some View {
        rootView()
            .attachedHoverState(
                $currentHoveredGrid,
                $currentHoveredNode
            )
            .onReceive(
                currentHoveredNode.publisher,
                perform: onGlyphEvent(_:)
            )
            .onReceive(
                link.input.sharedMouseDown, 
                perform: onMouseDown(_:)
            )
    }
    
    @ViewBuilder
    func rootView() -> some View {
        PointerHoverView(link: link)
    }
}


private extension SwiftGlyphHoverView {
    func onGlyphEvent(_ hoveredGlyph: NodePickingState.Event) {
        if
            let grid = GlobalInstances
                .userTextEditHolder
                .userSelectedGrid,
            hoveredGlyph.latestState?.targetGrid.id == grid.id,
            let index = hoveredGlyph.latestState?.node.instanceConstants?.bufferIndex
        {
            let range = NSRange(location: Int(index), length: 1)
            DispatchQueue.main.async {
                guard range != GlobalInstances
                    .userTextEditHolder
                    .userTextSelection else { return }
                
                GlobalInstances
                    .userTextEditHolder
                    .userTextSelection = range
            }
        }
    }
    
    func onMouseDown(_ mouseDown: OSEvent) {
        #if os(macOS)
        modifiers = mouseDown.modifierFlags
        #endif
        
        switch currentHoveredGrid {
        case .initial,
             .notFound,
             .useLast(_),
             .none:
            break
            
        case .matchesLast(_, let new),
                .foundNew(_, let new):
            GlobalInstances
                .gridStore
                .gridInteractionState
                .bookmarkedGrids
                .toggle(new.targetGrid)
            
            GlobalInstances
                .userTextEditHolder
                .userSelectedGrid = new.targetGrid
        }
    }
}
