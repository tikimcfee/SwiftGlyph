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
    @Published var caseInsensitive: Bool = true
    
    @Published var foundGrids = [CodeGrid]()
    @Published var missedGrids = [CodeGrid]()
    
    var bag = Set<AnyCancellable>()
    
    init() {
        $filterText
            .removeDuplicates()
            .combineLatest($caseInsensitive)
            .receive(on: DispatchQueue.global())
            .sink { streamInput, caseInsensitive in
                self.startSearch(
                    for: streamInput,
                    caseInsensitive: caseInsensitive
                )
            }.store(in: &bag)
    }
}

import BitHandling

extension GlobalSearchViewState {
    func startSearch(
        for input: String,
        caseInsensitive: Bool
    ) {
        let compute = GlobalInstances.gridStore.sharedConvert
        let grids = GlobalInstances.gridStore.gridCache.cachedGrids.values
        
        var rawQuery: [CharacterHashType] {
            input.map { $0.glyphComputeHash }
        }
        var upperCaseQuery: [CharacterHashType] {
            input.flatMap { $0.uppercased() }.map { $0.glyphComputeHash }
        }
        var lowerCaseQuery: [CharacterHashType] {
            input.flatMap { $0.lowercased() }.map { $0.glyphComputeHash }
        }
        var computedMode: QueryMode {
            caseInsensitive
            ? .caseInsensitive(upper: upperCaseQuery, lower: lowerCaseQuery)
            : .exact(raw: rawQuery)
        }
        
        DispatchQueue.concurrentPerform(iterations: grids.count) { index in
            do {
                let grid = grids[index]
                if grid.sourcePath?.isDirectory == true { return }
                
                var didMatch = false
                try compute.searchGlyphs_Conc(
                    in: grid.rootNode,
                    mode: computedMode,
                    collectionMatched: &didMatch,
                    clearOnly: input.count == 0
                )
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
