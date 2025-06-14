//
//  BasicIDEView.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/16/24.
//
#if os(macOS)

import SwiftUI
import MetalLink
import BitHandling

#if canImport(STTextViewSwiftUI)
import STTextViewSwiftUI
#endif

struct BasicIDEView: View {
    @State var leftPanelVisible: Bool = false
    
    @State var offsetYBrowser = 0.0
    @State var offsetYWindows = 0.0
    @State var showingInstructions = false
    
    @ObservedObject var bar = GlobalInstances.omnibarManager
    @State var barMode = FloatableViewMode.hidden
    
    var body: some View {
        ZStack {
            mainView
                .eraseToAnyView()
            
            GeometryReader { proxy in
                ResizablePanelView(
                    layoutMode: .horizontal,
                    sizes: [
                        320,
                        proxy.size.width - 320
                    ]
                ) { [
                    leftPanel
                        .eraseToAnyView(),
                    Spacer()
                        .eraseToAnyView()
                ] }
            }
            
            FloatingControlsCombo(
                showWindowing: false,
                sections: PanelSections.usableWindows
            )
            
            omnibar
        }
        .onReceive(bar.stateSubject) { state in
            barMode = switch state {
            case .inactive: .hidden
            case .visible: .displayedAsWindow
            }
        }
        .sheet(isPresented: $showingInstructions) {
            InstructionsView()
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                SGButton("", "sidebar.left", .toolbar) {
                    withAnimation(.linear(duration: 0.150)) {
                        leftPanelVisible.toggle()
                    }
                }
            }
            
            ToolbarItem(placement: .navigation) {
                SGButton("", "questionmark.circle", .toolbar) {
                    withAnimation(.linear(duration: 0.150)) {
                        showingInstructions.toggle()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var omnibar: some View {
        #if os(macOS)
        FloatableView(
            displayMode: $barMode,
            windowKey: .omnibar,
            innerViewBuilder: {
                OmnibarView()
            }
        )
        #else
        EmptyView()
        #endif
    }
}

extension BasicIDEView {
    private var mainView: some View {
        ZStack {
            previewSafeRenderView
            SwiftGlyphHoverView(link: GlobalInstances.defaultLink)
        }
    }
    
    @ViewBuilder
    private var leftPanel: some View {
        if leftPanelVisible {
            GeometryReader { proxy in
                ResizablePanelView(
                    layoutMode: .vertical,
                    sizes: [
                        400,
                        200,
                        200
                    ]
                ) { [
                    FileBrowserView(browserState: GlobalInstances.fileBrowserState, setMin: false)
                        .eraseToAnyView(),
                    
                    WorldFocusView(focus: GlobalInstances.gridStore.worldFocusController)
                        .eraseToAnyView(),
                    
                    VStack(alignment: .center) {
                        Text("Favorite Windows")
                        
                        AppControlsTogglesView(
                            state: GlobalInstances.appPanelState,
                            sections: [
                                .menuActions,
                                .githubTools,
                                .editor,
                                .appStatusInfo
                            ]
                        )
                    }
                    .eraseToAnyView()
                ] }
                .background(Color.primaryBackground)
            }
            .transition(.move(edge: .leading))
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

#endif
