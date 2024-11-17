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
        HStack {
            leftPanel
                .layoutPriority(0)
            
            mainView
                .layoutPriority(1)
        }
        .frame(width: 1920, height: 1080)
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
            ResizableLeftPanelView(layoutMode: .vertical)
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
