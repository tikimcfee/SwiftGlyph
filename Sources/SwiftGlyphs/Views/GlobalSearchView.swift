//
//  GlobalSearchView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/1/22.
//

import SwiftUI
import Combine
import MetalLink

class GlobalSearchViewState: ObservableObject {
    @Published var filterText = ""
    
    @Published var foundGrids = [CodeGrid]()
    @Published var missedGrids = [CodeGrid]()
    
    var bag = Set<AnyCancellable>()
    
    init() {
        $filterText.removeDuplicates()
            .receive(on: DispatchQueue.global())
            .sink { streamInput in
                self.startSearch(for: streamInput)
            }.store(in: &bag)
    }
}

extension GlobalSearchViewState {
    func startSearch(for input: String) {
        GlobalInstances.gridStore.searchContainer.search(input) { task in
            print("Filter completion reported: \(input)")
            
            DispatchQueue.main.async {
                self.foundGrids = task.searchLayout.values
                self.missedGrids = task.missedGrids.values
            }
            
//            GlobalInstances.gridStore.editor.applyAllUpdates(
//                sizeSortedAdditions: task.searchLayout.values,
//                sizeSortedMissing: task.missedGrids.values
//            )
        }
    }
}

struct GlobalSearchView: View {
    @StateObject var searchState = GlobalSearchViewState()
    
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
        let position = grid.worldPosition.translated(
            dX: grid.lengthX / 4.0,
            dZ: 64
        )
        
        var scrollBounds = grid.rootNode.worldBounds
        scrollBounds.min.x += 8
        scrollBounds.min.z += 8
        scrollBounds.max.z += 64
        
        GlobalInstances.debugCamera.interceptor.resetPositions()
        GlobalInstances.debugCamera.position = position
        GlobalInstances.debugCamera.rotation = .zero
        GlobalInstances.debugCamera.scrollBounds = scrollBounds
        GlobalInstances.gridStore.editor.snapping.searchTargetGrid = grid
    }
    
    var searchInput: some View {
        TextField(
            "Search",
            text: $searchState.filterText
        )
        .padding()
        .frame(minWidth: 256.0, idealWidth: 256.0, maxWidth: 512.00)
    }
}

struct GlobalSearchView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalSearchView()
    }
}
