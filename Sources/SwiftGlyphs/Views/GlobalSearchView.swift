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
        $filterText
            .removeDuplicates()
            .receive(on: DispatchQueue.global())
            .sink { streamInput in
                self.startSearch(for: streamInput)
            }.store(in: &bag)
    }
}

import BitHandling

extension GlobalSearchViewState {
    func startSearch(for input: String) {
        let compute = GlobalInstances.gridStore.sharedConvert
        let grids = GlobalInstances.gridStore.gridCache.cachedGrids.values
        let query = input.map { $0.glyphComputeHash }
        
        DispatchQueue.concurrentPerform(iterations: grids.count) { index in
            do {
                let grid = grids[index]
                if grid.sourcePath?.isDirectory == true { return }
                
                var didMatch = false
                try compute.searchGlyphs_Conc(
                    in: grid.rootNode,
                    with: query,
                    collectionMatched: &didMatch,
                    clearOnly: query.count == 0
                )
//                grid.rootNode.pausedInvalidate = true
//                grid.rootNode.scale = didMatch ? LFloat3(5, 5, 1) : LFloat3(1, 1, 1)
//                grid.rootNode.pausedInvalidate = false
//                grid.rootNode.rebuildTreeState()
                grid.applyFlag(.matchesSearch, didMatch)
                
            } catch {
                print(error)
            }
        }
//        GlobalInstances.gridStore.searchContainer.search(input) { task in
//            print("Filter completion reported: \(input)")
//            
//            DispatchQueue.main.async {
//                self.foundGrids = task.searchLayout.values
//                self.missedGrids = task.missedGrids.values
//            }
//            
////            GlobalInstances.gridStore.editor.applyAllUpdates(
////                sizeSortedAdditions: task.searchLayout.values,
////                sizeSortedMissing: task.missedGrids.values
////            )
//        }
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
        grid.displayFocused(GlobalInstances.debugCamera)
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
