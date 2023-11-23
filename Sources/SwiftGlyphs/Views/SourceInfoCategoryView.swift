//
//  SourceInfoCategoryView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/11/22.
//

import SwiftUI
import SwiftSyntax
import Combine
import MetalLink

public extension SourceInfoCategoryView {
    struct Interactions {
        public var expandedGrids: Set<CodeGrid.ID> = []
        
        public func isExpanded(grid: CodeGrid.ID) -> Bool {
            expandedGrids.contains(grid)
        }
        
        mutating func toggle(grid: CodeGrid.ID) {
            if expandedGrids.contains(grid) {
                expandedGrids.remove(grid)
            } else {
                expandedGrids.insert(grid)
            }
        }
        
        public init() {
            
        }
    }
    
    enum Mode {
        case idle
        case snapshot(CodeGridGlobalSemantics.Snapshot)
    }
}

public struct SourceInfoCategoryView: View {
    @State var interactions = Interactions()
    @State var mode: Mode = .idle
    
    public init() {
        
    }
    
    private func reset() {
        GlobalInstances.gridStore.globalSemantics.snapshotDefault()
    }
    
    public var body: some View {
        VStack {
            topControls
            viewForMode
        }
        .background(Color(red: 0.2, green: 0.2, blue: 0.25, opacity: 0.8))
        .onReceive(GlobalInstances.gridStore.globalSemantics.$categorySnapshot,
            perform: { newSnapshot in
                mode = .snapshot(newSnapshot)
            }
        )
        .onAppear {
            reset()
        }
    }
    
    var topControls: some View {
        HStack {
            Button("Reset snapshot", action: { reset() })
        }.padding(4)
    }
    
    @ViewBuilder
    var viewForMode: some View {
        switch mode {
        case .idle:
            EmptyView()
        case .snapshot(let snapshot):
            globalInfoRows(snapshot)
        }
    }

    func globalInfoRows(_ snapshot: CodeGridGlobalSemantics.Snapshot) -> some View {
        List(snapshot) { snapshotItem in
            participantView(snapshotItem)
        }
    }
    
    @ViewBuilder
    func participantView(_ snapshotParticipant: GlobalSemanticParticipant) -> some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text(snapshotParticipant.sourceGrid.fileName)
                    .font(.headline)
                    
                if let path = snapshotParticipant.sourceGrid.sourcePath?.path {
                    Text(path)
                        .font(.subheadline)
                        .padding([.top], 4)
                }
            }
            .padding([.top, .bottom], 8)
            .padding([.trailing], 8)
            
            // TODO: Use a tab view for categories, they're enumerable.
            if interactions.isExpanded(grid: snapshotParticipant.sourceGrid.id) {
                VStack(alignment: .leading) {
                    makeInfoRowGroup(
                        for: snapshotParticipant.queryCategories,
                        in: snapshotParticipant.sourceGrid
                    )
                }
            }
        }
        .background(.gray.opacity(0.5))
        .padding(4.0)
        .onTapGesture {
            interactions.toggle(grid: snapshotParticipant.sourceGrid.id)
        }
   }
    
    func makeInfoRowGroup(
        for categories: [SemanticInfoMap.Category],
        in targetGrid: CodeGrid
    ) -> some View {
        ForEach(categories, id: \.self) { category in
            let categoryMap = targetGrid.semanticInfoMap.map(for: category)
            if !categoryMap.isEmpty {
                Text(category.rawValue).underline().padding(.top, 8)
                infoRows(from: targetGrid, categoryMap)
            }
        }
    }
    
    func infoRows(from grid: CodeGrid, _ map: AssociatedSyntaxMap) -> some View {
        VStack(alignment: .leading) {
            ForEach(Array(map.keys), id:\.self) { (id: SyntaxIdentifier) in
                if let info = grid.semanticInfoMap.semanticsLookupBySyntaxId[id] {
                    semanticInfoRow(info, grid)
                } else {
                    Text("No SemanticInfo")
                }
            }
        }
        .padding(4.0)
    }
    
    func semanticInfoRow(_ info: SemanticInfo, _ grid: CodeGrid) -> some View {
        Text(info.referenceName)
            .font(Font.system(.caption, design: .monospaced))
            .padding(4)
            .overlay(Rectangle().stroke(Color.gray))
            .onTapGesture {
                let nodeBounds = GlobalInstances.gridStore
                    .nodeFocusController
                    .selected(id: info.syntaxId, in: grid)
                
                let position = LFloat3(
                    x: nodeBounds.width,
                    y: nodeBounds.top - 16,
                    z: nodeBounds.front + 64
                )
                
                GlobalInstances.debugCamera.interceptor.resetPositions()
                GlobalInstances.debugCamera.position = position
                GlobalInstances.debugCamera.rotation = .zero
            }
    }
}
