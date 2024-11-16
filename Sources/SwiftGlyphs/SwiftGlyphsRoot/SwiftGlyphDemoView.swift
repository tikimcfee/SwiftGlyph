#if os(iOS)
import ARKit
#endif
import SwiftUI
import MetalLink
import BitHandling

#if canImport(STTextViewSwiftUI)
import STTextViewSwiftUI
#endif

private let IsPreview = ProcessInfo.processInfo.environment["IS_PREVIEW"] == "1"

public struct SwiftGlyphDemoView : View {
    @State var showWindowing = true
    @State var showControls = true
    @State var inputState = FloatableViewMode.displayedAsWindow
    @ObservedObject var bar = GlobalInstances.omnibarManager
    
    public init() {
        
    }
    
    public var body: some View {
        rootView
    }
    
    private var rootView: some View {
        ZStack(alignment: .center) {
            previewSafeRenderView
            
            SwiftGlyphHoverView(link: GlobalInstances.defaultLink)
            
            conditionalControls
            
            omnibar
        }
        #if os(iOS)
        .ignoresSafeArea()
        #endif
    }
    
    @ViewBuilder
    var omnibar: some View {
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
    }
    
    @ViewBuilder
    var conditionalControls: some View {
        if showControls {
            #if os(macOS)
            macOSContent
            #else
            iOSContent
            #endif
        }
        floatingControlToggles
    }
        
    @ViewBuilder
    var floatingControlToggles: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack {
                    buttonImage("macwindow.on.rectangle").opacity(
                        showWindowing ? 1.0 : 0.5
                    ).onTapGesture {
                        GlobalInstances.appPanelState.toggleWindowControlsVisible()
                        showWindowing = GlobalInstances.appPanelState.isVisible(.windowControls)
                    }.onLongPressGesture {
                        GlobalInstances.appPanelState.resetSection(.windowControls)
                    }
                    
                    buttonImage("wrench.and.screwdriver").opacity(
                        showControls ? 1.0 : 0.5
                    ).onTapGesture {
                        showControls.toggle()
                    }
                }
            }
        }
        .padding()
    }
    
    #if os(macOS)
    @ViewBuilder
    var macOSContent: some View {
        ZStack(alignment: .topTrailing) {
            AppControlPanelView()
        }
    }
    #endif
    
    #if os(iOS)
    @ViewBuilder
    private var iOSContent: some View {
        ZStack(alignment: .topTrailing) {
            AppControlPanelView()
        }
    }
    #endif
    
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
    
    func buttonImage(_ name: String) -> some View {
        Image(systemName: name)
            .renderingMode(.template)
            .frame(width: 40, height: 40)
            .foregroundStyle(.red.opacity(0.8))
            .padding(6)
            .background(.blue.opacity(0.2))
            .contentShape(Rectangle())
            .clipShape(Circle())
    }
}

func SGButton(
    _ text: String,
    _ image: String,
    _ action: @escaping () -> Void
) -> some View {
    Button(
        action: action,
        label: {
            HStack {
                Text(text)
                if !image.isEmpty {
                    Image(systemName: image)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    )
    .buttonStyle(.plain)
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        SwiftGlyphDemoView()
    }
}
#endif
