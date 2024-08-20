//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/19/24.
//

import SwiftUI
import BitHandling
import MetalLink

private let BookmarkListViewStateName = "DragState-Bookmark-List-View"

struct BookmarkListView: View {
    @State var hoveredGrid: GridPickingState.Event?
    @State var hoveredNode: NodePickingState.Event?
    
    var body: some View {
        bookmarkListResizable
            .attachedHoverState($hoveredGrid, $hoveredNode)
            .onReceive(hoveredGrid.publisher) { event in
                
            }
    }
    
    @ViewBuilder
    var bookmarkListResizable: some View {
        ResizableComponentView(
            model: {
                AppStatePreferences.shared.getCustom(
                    name: BookmarkListViewStateName,
                    makeDefault: ComponentModel.init
                )
            },
            onSave: {
                AppStatePreferences.shared.setCustom(
                    name: BookmarkListViewStateName,
                    value: $0
                )
            },
            content: {
                bookmarkListContent
                    .padding(2)
                    .background(Color.primaryBackground.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        )
    }
    
    @ViewBuilder
    var bookmarkListContent: some View {
        if GlobalInstances.gridStore.gridInteractionState.bookmarkedGrids.isEmpty {
            Text("No Bookmarks").bold().padding()
        } else {
            let bookmarks = GlobalInstances
                .gridStore
                .gridInteractionState
                .bookmarkedGrids
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(bookmarks, id: \.id) { grid in
                    HStack(alignment: .top) {
                        gridOptionList(target: grid)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func gridOptionList(
        target grid: CodeGrid
    ) -> some View {
        HStack(alignment: .center) {
            SGButton("", "scope") {
                GlobalInstances.debugCamera.updating {
                    $0.interceptor.resetPositions()
                    $0.position = grid.worldPosition.translated(
                        dX: grid.lengthX / 2.0,
                        dY: max(-32, grid.bottom),
                        dZ: 96
                    )
                    $0.rotation = .zero
                }
            }
            
            SGButton("", "xmark") {
                GlobalInstances
                    .gridStore
                    .gridInteractionState
                    .bookmarkedGrids
                    .removeAll(where: { $0.id == grid.id })
            }
        }
        .padding(4)
        .background(Color.primaryBackground.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
