#if os(iOS)
import ARKit
#endif
import SwiftUI
import MetalLink
import BitHandling

private extension SwiftGlyphDemoView {
    var receiver: DefaultInputReceiver { DefaultInputReceiver.shared }
}

public struct SwiftGlyphDemoView : View {
    public enum Tab {
        case metalView
        case actions
    }
    
    public enum Screen {
        case fileBrowser
        case showActions
        case showGitFetch
        case root
    }
    
    @State var screen: Screen = .root
    @State var tab: Tab = .metalView
    
    @StateObject var browserState = FileBrowserViewState()
    
    public init() {
        
    }
    
    func setScreen(_ new: Screen) {
        withAnimation(.snappy(duration: 0.333)) {
            self.screen = screen == new
                ? .root
                : new
        }
    }
    
    public var body: some View {
        rootView
            .environmentObject(MultipeerConnectionManager.shared)
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
    
    var fileButtonName: String {
        if screen == .fileBrowser {
            return "Hide"
        } else {
            return "\(browserState.files.first?.path.lastPathComponent ?? "No Files Selected")"
        }
    }
    
    private var rootView: some View {
        ZStack(alignment: .topTrailing) {
            GlobalInstances.createDefaultMetalView()
            
            #if os(macOS)
            HStack {
                topSafeAreaContent
                Spacer()
            }
            
            VStack {
                Spacer()
                bottomSafeAreaContent
            }
            #endif
        }
        #if os(iOS)
        .ignoresSafeArea()
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            bottomSafeAreaContent
        }
        .safeAreaInset(edge: .top) {
            topSafeAreaContent
        }
        #endif
    }
    
    var topSafeAreaContent: some View {
        VStack(alignment: .trailing, spacing: 0) {
            AppStatusView(status: GlobalInstances.appStatus)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var screenViewBottom: some View {
        switch screen {
        case .fileBrowser:
            fileBrowserContentView
                .zIndex(1)
            
        case .showActions:
            actionsContent
                .zIndex(2)
            
        case .showGitFetch:
            GitHubClientView()
                .zIndex(3)
            
        case .root:
            EmptyView()
                .zIndex(4)
        }
    }
    
    var bottomSafeAreaContent: some View {
        VStack(alignment: .trailing) {
            screenViewBottom
                .padding(.leading)
                .transition(.move(edge: .trailing))
                .zIndex(5)

            HStack {
                controlsButton
                showFileBrowserButton
            }.zIndex(6)
        }
        .padding(.vertical)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    var fileBrowserContentView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            FileBrowserView(browserState: browserState)
                .frame(maxHeight: 640)
                .padding(.top, 8)
            
            HStack {
                downloadFromGithubButton
            }
            .padding(.top, 8)
        }
    }

    
    var actionsContent: some View {
        VStack {
            saveAtlasButton
            deleteAtlas
            preloadAtlasButton
        }
    }
    
    var controlsButton: some View {
        Image(systemName: "gearshape.fill")
            .renderingMode(.template)
            .foregroundStyle(.red.opacity(0.8))
            .padding(6)
            .background(.blue.opacity(0.2))
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                setScreen(.showActions)
            }
    }
    
    var showFileBrowserButton: some View {
        button(fileButtonName, "") {
            setScreen(.fileBrowser)
        }
    }
    
    var downloadFromGithubButton: some View {
        button(
            "Download from GitHub",
            "square.and.arrow.down.fill"
        ) {
            setScreen(.showGitFetch)
        }
    }
    
    var deleteAtlas: some View {
        Button("Reset (delete) atlas") {
            GlobalInstances.resetAtlas()
        }
    }
    
    var saveAtlasButton: some View {
        Button("Save Glyph Atlas") {
            GlobalInstances.defaultAtlas.save()
        }
    }
    
    var preloadAtlasButton: some View {
        Button("Preload Glyph Atlas") {
            GlobalInstances.defaultAtlas.preload()
        }
    }
    
    var importFilesButton: some View {
        Button("Select Directory") {
            GlobalInstances
                .debugCamera // lol wow man
                .interceptor
                .onNewFileOperation?(.openDirectory)
        }.keyboardShortcut("o", modifiers: .command)
    }
    
    func button(
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
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        )
        .buttonStyle(.plain)
    }
}

#if os(macOS)
private extension SwiftGlyphDemoView {
    private static var window: NSWindow?
    
    func macOSViewDidAppear() {
        let rootWindow = makeRootWindow()
        GlobablWindowDelegate.instance.registerRootWindow(rootWindow)
        rootWindow.contentView = makeRootContentView()
        rootWindow.makeKeyAndOrderFront(nil)
        Self.window = rootWindow
    }
    
    func makeRootContentView() -> NSView {
        let contentView = SwiftGlyphDemoView()
            .environmentObject(MultipeerConnectionManager.shared)
            .onAppear {
                // Set initial state on appearance
                GlobalInstances.fileBrowser.loadRootScopeFromDefaults()
                GlobalInstances.gridStore.gridInteractionState.setupStreams()
                GlobalInstances.defaultRenderer.renderDelegate = GlobalInstances.swiftGlyphRoot
            }
            .onDisappear {
                URL.dumpAndDescopeAllKnownBookmarks()
            }
        
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
            .frame(width: 1024, height: 800)
    }
}
#endif
