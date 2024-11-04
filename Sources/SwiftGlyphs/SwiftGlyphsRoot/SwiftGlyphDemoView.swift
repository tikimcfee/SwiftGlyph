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
    
    public init() {
        
    }
    
    public var body: some View {
        rootView
    }
    
    private var rootView: some View {
        ZStack(alignment: .bottomTrailing) {
            previewSafeRenderView
            
            SwiftGlyphHoverView(
                link: GlobalInstances.defaultLink
            )
            
            if showControls {
                #if os(macOS)
                macOSContent
                #else
                iOSContent
                #endif
            }
            
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
            .padding()
        }
        #if os(iOS)
        .ignoresSafeArea()
        #endif
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

#if os(macOS)
private extension SwiftGlyphDemoView {
    private static var window: NSWindow?
    
    func macOSViewDidAppear() {
        let rootWindow = makeRootWindow()
        GlobalWindowDelegate.instance.registerRootWindow(rootWindow)
        rootWindow.contentView = makeRootContentView()
        rootWindow.makeKeyAndOrderFront(nil)
        Self.window = rootWindow
    }
    
    func makeRootContentView() -> NSView {
        let contentView = SwiftGlyphDemoView()
        return NSHostingView(rootView: contentView)
    }
    
    func makeRootWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1440, height: 1024),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        return window
    }
}
#endif


#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        SwiftGlyphDemoView()
    }
}
#endif
