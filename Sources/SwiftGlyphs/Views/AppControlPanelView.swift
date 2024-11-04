//
//  AppControlPanelView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/25/21.
//

import SwiftUI
import Combine
import MetalLink
import MetalLinkHeaders
import MetalLinkResources

struct AppControlPanelView: View {
    @ObservedObject var state: AppControlPanelState = GlobalInstances.appPanelState
    
    var body: some View {
        allPanelsGroup
    }
}

extension AppControlPanelView {
    
    var allPanelsGroup: some View {
        ForEach(PanelSections.allCases) { section in
            floatingViewWrapper(for: section)
        }
    }
    
    @ViewBuilder
    func floatingViewWrapper(for panel: PanelSections) -> some View {
        FloatableView(
            displayMode: state.vendPanelBinding(panel),
            windowKey: panel,
            resizableAsSibling: true,
            innerViewBuilder: {
                panelView(for: panel)
            }
        )
    }
    
    @ViewBuilder
    func panelView(for panel: PanelSections) -> some View {
        switch panel {
        case .windowControls:
            AppWindowTogglesView(state: state)
            
        case .appStatusInfo:
            AppStatusView(
                status: GlobalInstances.appStatus
            )
            
        case .gridStateInfo:
            SwiftGlyphHoverView(
                link: GlobalInstances.defaultLink
            )
            
        case .globalSearch:
            GlobalSearchView()
            
        case .editor:
            TextViewWrapper()
            
        case .directories:
            FileBrowserView(
                browserState: GlobalInstances.fileBrowserState
            )
            
        case .semanticCategories:
            SourceInfoCategoryView()
                .frame(width: 780, height: 640)
            
        case .hoverInfo:
            SyntaxHierarchyView()
            
        case .tracingInfo:
            Text("No tracin' on mobile because abstractions.")
            
        case .githubTools:
            GitHubClientView()
            
        case .focusState:
            WorldFocusView(
                focus: GlobalInstances.gridStore.worldFocusController
            )
            
        case .menuActions:
            MenuActions()
            
        case .bookmarks:
            BookmarkListView()
        }
    }
}

// MARK: - -- Previews --

#if DEBUG
struct SourceInfo_Previews: PreviewProvider {
    static let sourceString = """
func helloWorld() {
  let test = ""
  let another = "X"
  let somethingCrazy: () -> Void = { [weak self] in
     print("Hello, world!")
  }
  somethingCrazy()
}
"""
    
    static var sourceGrid: CodeGrid = {
        let builder = GlobalInstances.gridStore.builder
        let grid = builder.createConsumerForNewGrid().consumeText(text: sourceString)
        return grid
    }()
    
    static var sourceInfo = WrappedBinding<SemanticInfoMap>({
        let info = sourceGrid.semanticInfoMap
        return info
    }())
    
    static var randomId: String {
//        let characterIndex = sourceString.firstIndex(of: "X") ?? sourceString.startIndex
//        let offset = characterIndex.utf16Offset(in: sourceString)
        return "no-id" // TODO: Expose node ids somehow
    }
    
    static var sourceState: AppControlPanelState = {
        let state = AppControlPanelState()
        return state
    }()

    static var previews: some View {
        return Group {
            SourceInfoCategoryView()
                .environmentObject(sourceState)
        }
    }
}
#endif
