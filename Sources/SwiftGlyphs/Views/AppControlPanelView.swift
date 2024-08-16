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

#if canImport(STTextViewSwiftUI)
import STTextViewSwiftUI
#endif

struct AppControlPanelView: View {
    @StateObject var state: AppControlPanelState = AppControlPanelState()
    
    var body: some View {
//        VStack(alignment: .leading) {
            allPanelsGroup
//        }
    }
}

extension AppControlPanelView {
    
    var allPanelsGroup: some View {
        ForEach(PanelSections.allCases) { section in
            viewWithDisplayState(for: section)
        }
    }
    
    @ViewBuilder
    func viewWithDisplayState(for section: PanelSections) -> some View {
        switch state.visiblePanelStates.source[section, default: .hidden] {
        case .displayedAsSibling,
             .displayedAsWindow:
            makeFloatingView(for: section)
        case .hidden:
            EmptyView()
        }
    }
    
    @ViewBuilder
    func makeFloatingView(for panel: PanelSections) -> some View {
        FloatableView(
            displayMode: state.vendPanelBinding(panel),
            windowKey: panel,
            resizableAsSibling: true,
            innerViewBuilder: {
                panelView(for: panel)
                    .border(.black, width: 2.0)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2, opacity: 0.2))
            }
        )
    }
    
    @ViewBuilder
    func panelView(for panel: PanelSections) -> some View {
        switch panel {
        case .appStatusInfo:
            appStatusView
        case .gridStateInfo:
            gridStateView
        case .globalSearch:
            globalSearchView
        case .editor:
            editorView
        case .directories:
            fileBrowserView
        case .semanticCategories:
            semanticCategoriesView
        case .hoverInfo:
            hoverInfoView
        case .tracingInfo:
            traceInfoView
        case .windowControls:
            windowControlsView
        case .githubTools:
            gitHubTools
        case .focusState:
            focusState
        case .testStreamInput:
            editorView
        }
    }
    
    
    @ViewBuilder
    var focusState: some View {
        WorldFocusView(
            focus: GlobalInstances.gridStore.worldFocusController
        )
    }
    
    @ViewBuilder
    var appStatusView: some View {
        AppStatusView(
            status: GlobalInstances.appStatus
        )
    }
    
    @ViewBuilder
    var gitHubTools: some View {
        GitHubClientView()
    }
    
    @ViewBuilder
    var gridStateView: some View {
        SwiftGlyphHoverView(
            link: GlobalInstances.defaultLink
        )
    }
    
    var globalSearchView: some View {
        GlobalSearchView()
    }
    
    @ViewBuilder
    var semanticCategoriesView: some View {
        SourceInfoCategoryView()
            .frame(width: 780, height: 640)
            .environmentObject(state)
    }
    
    @ViewBuilder
    var hoverInfoView: some View {
        SyntaxHierarchyView()
    }

    @ViewBuilder
    var traceInfoView: some View {
        #if !os(iOS)
        Text("No tracin' on desktop because we movin' on.")
        #else
        Text("No tracin' on mobile because abstractions.")
        #endif
    }
    
    @ViewBuilder
    var editorView: some View {
        #if os(macOS)
        TextView(
            text: GlobalInstances.swiftGlyphRoot.holder.inputBinding.rootUserInput,
            selection: GlobalInstances.swiftGlyphRoot.holder.inputBinding.selection,
            options: [.highlightSelectedLine],
            plugins: []
        )
        .textViewFont(.preferredFont(forTextStyle: .body))
        #else
        Text("Text editing is hard for da little phone buddies. Gotta have big beefy operating system to actually edit words. Go figure.")
        #endif
        
    }
    
    @ViewBuilder
    var fileBrowserView: some View {
        FileBrowserView(
            browserState: state.fileBrowserState
        )
    }
    
    var windowControlsView: some View {
        AppControlPanelToggles(state: state)
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
