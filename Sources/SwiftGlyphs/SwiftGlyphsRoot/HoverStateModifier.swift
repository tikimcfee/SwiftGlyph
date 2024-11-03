//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/18/24.
//

import SwiftUI

struct HoverStateModifier: ViewModifier {
    @Binding var currentHoveredGrid: GridPickingState.Event?
    @Binding var currentHoveredNode: NodePickingState.Event?
    
    func body(content: Content) -> some View {
        content
            .onReceive(
                GlobalInstances.gridStore
                    .nodeHoverController
                    .sharedGridEvent
                    .receive(on: RunLoop.main)
            ) { self.currentHoveredGrid = $0 }
            .onReceive(
                GlobalInstances.gridStore
                    .nodeHoverController
                    .sharedGlyphEvent
                    .receive(on: RunLoop.main)
            ) { self.currentHoveredNode = $0 }
    }
}

extension View {
    func attachedHoverState(
        _ currentHoveredGrid: Binding<GridPickingState.Event?>,
        _ currentHoveredNode: Binding<NodePickingState.Event?>
    ) -> some View {
        modifier(
            HoverStateModifier(
                currentHoveredGrid: currentHoveredGrid,
                currentHoveredNode: currentHoveredNode
            )
        )
    }
}
