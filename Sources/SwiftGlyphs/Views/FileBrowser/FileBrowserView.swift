//
//  FileBrowserView.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 12/10/21.
//

import Combine
import SwiftUI
import Foundation
import BitHandling

public struct FileBrowserView: View {
    
    public typealias RowType = [FileBrowser.Scope]
    @StateObject var browserState: FileBrowserViewState
    @State var hoveredScope: FileBrowser.Scope? = .none
    func isHovered(_ scope: FileBrowser.Scope) -> Bool {
        hoveredScope == scope
    }
    
    public init(
        browserState: FileBrowserViewState
    ) {
        self._browserState = StateObject(wrappedValue: browserState)
    }
    
    public var body: some View {
        rootView
            .padding(4.0)
            .frame(
                minWidth: 256.0,
                minHeight: 256.0,
                alignment: .leading
            )
    }
    
    var rootView: some View {
        VStack(alignment: .leading) {
            fileRows(browserState.files)
            Spacer()
            searchInput
        }
    }
    
    
    var searchInput: some View {
        TextField(
            "Search",
            text: $browserState.filterText
        )
    }
    
    @ViewBuilder
    func fileRows(_ rows: RowType) -> some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(rows) { scope in
                    rowForScope(scope)
                }
            }
        }
    }
    
    @ViewBuilder
    func rowForScope(_ scope: FileBrowser.Scope) -> some View {
        FileBrowserRowView(
            scope: scope,
            depth: pathDepths(scope),
            hoveredScope: $hoveredScope,
            onEvent: { fileEvent in
                GlobalInstances
                    .fileBrowser
                    .fileSelectionEvents = fileEvent
            }
        )
    }
    
    func pathDepths(_ scope: FileBrowser.Scope) -> Int {
        GlobalInstances
            .fileBrowser
            .distanceToRoot(scope)
    }
}

#if DEBUG
struct FileBrowserView_Previews: PreviewProvider {
    
    static let testPaths: [FileBrowser.Scope] = [
        .directory(URL(fileURLWithPath: "/Users/lugo/localdev/viz")),
    ]
    
    static let testState: FileBrowserViewState = {
        let state = FileBrowserViewState()
//        state.files = testFiles
        return state
    }()
    
    static var previews: some View {
        FileBrowserView(browserState: testState)
            .onAppear {
                GlobalInstances.fileBrowser.setRootScope(testPaths[0].path)
            }
            .frame(width: 600, height: 600)
    }
}
#endif



