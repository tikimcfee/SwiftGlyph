//
//  BasicIDEView.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/16/24.
//

#if os(iOS)
import ARKit
#endif
import SwiftUI
import MetalLink
import BitHandling

#if canImport(STTextViewSwiftUI)
import STTextViewSwiftUI
#endif

struct BasicIDEView: View {
    @State var leftPanelVisible: Bool = true
    
    @State var offsetYBrowser = 0.0
    @State var offsetYWindows = 0.0
        
    var body: some View {
        ResizablePanelView(layoutMode: .horizontal) {
            conditionalViews
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                SGButton("", "sidebar.left", .toolbar) {
                    withAnimation {
                        leftPanelVisible.toggle()
                    }
                }
            }
        }
    }
    
    var conditionalViews: [AnyView] {
        if leftPanelVisible {
            [
                leftPanel.eraseToAnyView(),
                mainView.eraseToAnyView()
            ]
        } else {
            [
                mainView.eraseToAnyView()
            ]
        }
    }
}

extension BasicIDEView {
    private var mainView: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                WorldFocusView(focus: GlobalInstances.gridStore.worldFocusController)
            }
            .frame(minWidth: 320)
            Spacer()
            previewSafeRenderView
        }
    }
    
    @ViewBuilder
    private var leftPanel: some View {
        if leftPanelVisible {
            ResizablePanelView(layoutMode: .vertical) { [
                FileBrowserView(browserState: GlobalInstances.fileBrowserState, setMin: false)
                    .eraseToAnyView(),
                AppWindowTogglesView(state: GlobalInstances.appPanelState)
                    .eraseToAnyView(),
                AppStatusView(status: GlobalInstances.appStatus)
                    .eraseToAnyView()
            ] }
        }
    }
    
    @ViewBuilder
    private var previewSafeRenderView: some View {
        if IsPreview {
            Spacer()
        } else {
            GlobalInstances.createDefaultMetalView()
                .onAppear {
                    // Set initial state on appearance
                    GlobalInstances.fileBrowser.loadRootScopeFromDefaults()
                    GlobalInstances.gridStore.gridInteractionState.setupStreams()
                    GlobalInstances.defaultRenderer.renderDelegate = GlobalInstances.swiftGlyphRoot
                }
                .onDisappear {
                    // Stop accessing URLs safely to remain a good citizen.
                    URL.dumpAndDescopeAllKnownBookmarks()
                }
        }
    }
}

#Preview {
    BasicIDEView()
}
