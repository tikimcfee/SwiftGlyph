#if os(iOS)
import ARKit
#endif
import SwiftUI
import MetalLink
import BitHandling

private let IsPreview = ProcessInfo.processInfo.environment["IS_PREVIEW"] == "1"

public extension SwiftGlyphDemoView {
    enum Tab {
        case metalView
        case actions
    }
    
    enum Screen {
        case fileBrowser
        case showActions
        case showGitFetch
        case root
    }
}

private extension SwiftGlyphDemoView {
    var receiver: DefaultInputReceiver { DefaultInputReceiver.shared }
    
    var fileButtonName: String {
        let name = "\(browserState.files.first?.path.lastPathComponent ?? "No Directory")"
        if screen == .fileBrowser {
            return "[\(name)] - Hide"
        } else {
            return name
        }
    }
    
    func setScreen(_ new: Screen) {
        withAnimation(.easeOut(duration: 0.333)) {
            self.screen = screen == new
                ? .root
                : new
        }
    }
}

public struct SwiftGlyphDemoView : View {
    @State var screen: Screen = .root
    @State var showBottomControls = false
    @StateObject var browserState = FileBrowserViewState()
    
    public init() {
        
    }
    
    public var body: some View {
        rootView
            .environmentObject(MultipeerConnectionManager.shared)
    }
    
    
    @ViewBuilder
    private var previewSafeView: some View {
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
    
    private var rootView: some View {
        ZStack(alignment: .topTrailing) {
            previewSafeView
            
            #if os(macOS)
            HStack {
                topSafeAreaContent
                    .padding()
                Spacer()
            }
            
            VStack(alignment: .trailing) {
                Spacer()
                screenView
                bottomSafeAreaContent
                    .padding(.vertical)
                    .padding(.horizontal)
            }
            #else
            VStack(alignment: .trailing) {
                Spacer()
                screenView
                    .frame(maxHeight: 600)
                    
                HStack(alignment: .top) {
                    Spacer()
                    let image = showBottomControls
                        ? "chevron.right"
                        : "chevron.left"
                    
                    buttonImage(image).onTapGesture {
                        withAnimation(.easeOut(duration: 0.333)) {
                            showBottomControls.toggle()
                        }
                    }
                    .padding([.leading, .bottom, .trailing], 24)
                    
                    if showBottomControls {
                        bottomSafeAreaContent
                            .padding([.trailing, .bottom], 24)
                            .frame(maxWidth: .infinity)
                            .transition(
                                .move(edge: .trailing)
                                    .combined(with: .slide)
                            )
                            .layoutPriority(1)
                            .zIndex(1)
                    }
                }
                .padding(.top)
                .background(
                    showBottomControls
                        ? Color.gray.opacity(0.3)
                        : Color.clear
                )
            }
            .frame(maxWidth: .infinity)
            #endif
        }
        #if os(iOS)
        .ignoresSafeArea()
        .safeAreaInset(edge: .top, alignment: .leading) {
            topSafeAreaContent
                .padding()
        }
        #endif
    }
    
    var topSafeAreaContent: some View {
        AppStatusView(status: GlobalInstances.appStatus)
    }
    
    @ViewBuilder
    var screenView: some View {
        Group {
            switch screen {
            case .fileBrowser:
                fileBrowserContentView
                    .zIndex(1)
                
            case .showActions:
                actionsContent
                    .padding(.horizontal)
                    .zIndex(2)
                
            case .showGitFetch:
                GitHubClientView()
                    .zIndex(3)
                
            case .root:
                EmptyView()
                    .zIndex(4)
            }
        }
        .transition(.move(edge: .trailing))
        .zIndex(5)
    }
    
    var bottomSafeAreaContent: some View {
        HStack(alignment: .top) {
            buttonImage("gearshape.fill").onTapGesture {
                setScreen(.showActions)
            }
            Spacer()
            VStack(alignment: .trailing) {
                showFileBrowserButton
                downloadFromGithubButton
            }
        }
        .zIndex(6)
    }
    
    @ViewBuilder
    var fileBrowserContentView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            FileBrowserView(browserState: browserState)
                .frame(maxHeight: 640)
                .padding(.top, 8)
        }
    }

    var actionsContent: some View {
        VStack(alignment: .leading) {
            saveAtlasButton
            deleteAtlas
            preloadAtlasButton
        }
        .buttonStyle(.bordered)
        .padding()
        .background(Color.primaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    func buttonImage(_ name: String) -> some View {
        Image(systemName: name)
            .renderingMode(.template)
            .foregroundStyle(.red.opacity(0.8))
            .padding(6)
            .background(.blue.opacity(0.2))
            .contentShape(Rectangle())
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    var showFileBrowserButton: some View {
        button(fileButtonName, "") {
            setScreen(.fileBrowser)
        }
    }
    
    var downloadFromGithubButton: some View {
        button(
            screen == .showGitFetch
                ? "Hide"
                : "GitHub",
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
                .background(Color.primaryBackground)
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