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
    
    let sections: [PanelSections]
    
    init(sections: [PanelSections]) {
        self.sections = sections
    }
    
    var body: some View {
        allPanelsGroup
    }
}

extension AppControlPanelView {
    
    var allPanelsGroup: some View {
        ForEach(sections) { section in
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
            AppControlsTogglesView(state: state, sections: sections)
            
        case .appStatusInfo:
            AppStatusView(
                status: GlobalInstances.appStatus
            )
            
        case .gridStateInfo:
            EmptyView()
//            SwiftGlyphHoverView(
//                link: GlobalInstances.defaultLink
//            )
            
        case .globalSearch:
            Text("""
            Coming soon here:
            - Global fuzzy text search with visual highlighting.
            """)
//            GlobalSearchView()
            
        case .editor:
            TextViewWrapper()
            
        case .directories:
            FileBrowserView(
                browserState: GlobalInstances.fileBrowserState
            )
            
        case .semanticCategories:
            Text("""
            Coming soon here:
            - View, highlight, and jump to AST nodes and types.
            """)
//            SourceInfoCategoryView()
//                .frame(width: 780, height: 640)
            
        case .hoverInfo:
            Text("""
            Coming soon here:
            - Tap and hover on files to view statistics and app state.
            """)
//            SyntaxHierarchyView()
            
        case .tracingInfo:
            Text("Trace highlighting coming soon!")
            
        case .githubTools:
            GitHubClientView()
            
        case .focusState:
            WorldFocusView(
                focus: GlobalInstances.gridStore.worldFocusController
            )
            
        case .menuActions:
            MenuActions()
            
        case .bookmarks:
            Text("""
            Coming soon here:
            - Quick jumps and shortcuts between open files and folders.
            """)
            
        case .unregistered:
            Text("""
            Oh look, you found a bug - well done and all that!
            """)
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
