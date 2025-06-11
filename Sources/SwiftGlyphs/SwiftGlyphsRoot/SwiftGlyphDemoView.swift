#if os(iOS)
import ARKit
#endif
import SwiftUI
import MetalLink
import BitHandling

#if canImport(STTextViewSwiftUI)
import STTextViewSwiftUI
#endif

public let IsPreview = ProcessInfo.processInfo.environment["IS_PREVIEW"] == "1"

public struct SwiftGlyphDemoView : View {
    public init() {
        
    }
    
    public var body: some View {
        #if os(macOS)
        BasicIDEView()
        #else
        floatingWindowRootView
        #endif
    }
    
    private var floatingWindowRootView: some View {
        ZStack(alignment: .center) {
            previewSafeRenderView
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            
            SwiftGlyphHoverView(link: GlobalInstances.defaultLink)
            
            FloatingControlsCombo(sections: PanelSections.usableWindows)
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

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        SwiftGlyphDemoView()
    }
}
#endif
