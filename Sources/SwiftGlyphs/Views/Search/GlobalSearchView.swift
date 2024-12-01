//
//  GlobalSearchView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/1/22.
//

import SwiftUI
import Combine
import MetalLink
import BitHandling

struct GlobalSearchView: View {
    @ObservedObject var searchState = GlobalInstances.searchState
    
    var body: some View {
        VStack(alignment: .leading) {
            searchInput
            ScrollLockView()
            gridListColumns
        }
        .padding()
    }
    
    @ViewBuilder
    var gridListColumns: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Matches")
                foundGrids
            }
            VStack(alignment: .leading) {
                Text("Misses")
                missedGrids
            }
        }
        .padding()
        .border(.gray)
    }
    
    var foundGrids: some View {
        gridList(searchState.foundGrids)
    }
    
    var missedGrids: some View {
        gridList(searchState.missedGrids)
    }
    
    func gridList(_ grids: [CodeGrid]) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(grids) { grid in
                    gridButton(grid)
                    Divider()
                }
            }
        }
        .frame(width: 256.0, height: 196.0)
        .border(.gray)
    }
    
    @ViewBuilder
    func gridButton(_ grid: CodeGrid) -> some View {
        Text(grid.fileName)
            .onTapGesture {
                selectGrid(grid)
            }
    }
    
    func selectGrid(_ grid: CodeGrid) {
        grid.displayFocused(GlobalInstances.debugCamera)
        GlobalInstances.gridStore.editor.snapping.searchTargetGrid = grid
    }
    
    var searchInput: some View {
        HStack {
            TextField(
                "Search",
                text: $searchState.filterText
            )
            .padding()
            .frame(minWidth: 256.0, idealWidth: 256.0, maxWidth: 512.00)
            
            Toggle(isOn: $searchState.caseInsensitive) {
                Text("Ignore case")
            }
        }
    }
}

struct GlobalSearchView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalSearchView()
    }
}
