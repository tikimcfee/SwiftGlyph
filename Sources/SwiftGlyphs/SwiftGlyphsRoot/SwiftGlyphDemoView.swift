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
    @State var inputState = FloatableViewMode.displayedAsWindow
    @ObservedObject var bar = GlobalInstances.omnibarManager
    
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
            
            SwiftGlyphHoverView(link: GlobalInstances.defaultLink)
            
            FloatingControlsCombo(sections: PanelSections.usableWindows)
            
            omnibar
        }
        #if os(iOS)
        .ignoresSafeArea()
        #endif
    }
    
    @ViewBuilder
    var omnibar: some View {
        #if os(macOS)
        FloatableView(
            displayMode: .init(
                get: { GlobalInstances.omnibarManager.isOmnibarVisible ? .displayedAsWindow : .hidden },
                set: { _ in }
            ),
            windowKey: .omnibar,
            resizableAsSibling: false,
            innerViewBuilder: {
                OmnibarView()
            }
        )
        #else
        EmptyView()
        #endif
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
