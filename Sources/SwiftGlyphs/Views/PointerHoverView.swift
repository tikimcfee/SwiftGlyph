//
//  PointerHoverView.swift
//  
//
//  Created by Ivan Lugo on 11/12/24.
//

import SwiftUI
import MetalLink
import BitHandling

struct PointerHoverView: View {
    let link: MetalLink
    
    @State private var currentHoveredGrid: GridPickingState.Event?
    @State private var currentHoveredNode: NodePickingState.Event?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                gridStateView()
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: .topLeading
            )
            .attachedToMousePosition(in: proxy, with: link)
            .attachedHoverState(
                $currentHoveredGrid,
                $currentHoveredNode
            )
        }
    }
    
    @ViewBuilder
    func gridStateView() -> some View {
        switch currentHoveredGrid {
        case let .foundNew(_, event),
             let .matchesLast(_, event):
            fileNameView(event.targetGrid)
            
        case .initial,
             .notFound,
             .useLast(_),
             .none:
            EmptyView()
        }
    }
    
    @ViewBuilder
    func fileNameView(
        _ grid: CodeGrid
    ) -> some View {
        VStack(alignment: .leading) {
            Text(grid.fileName)
                .font(.headline)
                .bold()
        }
        .padding(4)
        .background(Color.primaryBackground.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}
