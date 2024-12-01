//
//  GlobalSearchViewState.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/28/24.
//


import SwiftUI
import Combine
import MetalLink
import BitHandling

public class GlobalSearchViewState: ObservableObject {
    @Published var filterText = ""
    @Published var caseInsensitive: Bool = true
    
    @Published var foundGrids = [CodeGrid]()
    @Published var missedGrids = [CodeGrid]()
    
    var bag = Set<AnyCancellable>()
    
    public init() {
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
    }
}

