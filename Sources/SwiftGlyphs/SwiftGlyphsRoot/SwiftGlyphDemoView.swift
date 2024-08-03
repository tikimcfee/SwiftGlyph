#if os(iOS)
import ARKit
#endif
import SwiftUI
import MetalLink
import BitHandling
import STTextViewSwiftUI

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
        withAnimation(.snappy(duration: GlobalLiveConfig.Default.uiAnimationDuration)) {
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
    
    @State var inputState = FloatableViewMode.displayedAsWindow
    
    
    public init() {
        
    }
    
    public var body: some View {
        rootView
//            .environmentObject(MultipeerConnectionManager.shared)
    }
    
    private var rootView: some View {
        ZStack(alignment: .topTrailing) {
            previewSafeView
            
            SwiftGlyphHoverView(
                link: GlobalInstances.defaultLink
            )
            
            #if os(macOS)
            macOSContent
            #else
            iOSContent
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
    
    #if os(macOS)
    @ViewBuilder
    var macOSContent: some View {
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
    }
    #endif
    
    #if os(iOS)
    @ViewBuilder
    private var iOSContent: some View {
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
                    withAnimation(.snappy(duration: GlobalLiveConfig.Default.uiAnimationDuration)) {
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
    }
    #endif
    
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
            
            testInputStreamWindow

            Spacer()
            VStack(alignment: .trailing) {
                showFileBrowserButton
                downloadFromGithubButton
            }
        }
        .zIndex(6)
    }
    
    @ViewBuilder
    var testInputStreamWindow: some View {
        FloatableView(
            displayMode: $inputState,
            windowKey: .githubTools,
            maxSiblingSize: .init(width: 400, height: 300),
            resizableAsSibling: true,
            innerViewBuilder: {
                VStack {
                    TextView(
                        text: GlobalInstances.swiftGlyphRoot.holder.inputBinding.rootUserInput,
                        selection: GlobalInstances.swiftGlyphRoot.holder.inputBinding.selection,
                        options: [.highlightSelectedLine],
                        plugins: []
                    )
                    .textViewFont(.preferredFont(forTextStyle: .body))
                }
                .padding()
                
//                    VStack {
//                        Button("Load File") {
//                            openFile { file in
//                                if
//                                    case let .success(url) = file,
//                                    let attr = try? AttributedString(contentsOf: url, including: \.swiftUI)
//                                {
//                                    GlobalInstances.swiftGlyphRoot.holder.data.rootUserInput = attr
//                                }
//                            }
//                        }
//                    }
            }
        )
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
        List {
            Section("Atlas") {
                LabeledContent("Save texture atlas", content: {
                    saveAtlasButton
                })
                
                LabeledContent("Totally clear atlas", content: {
                    deleteAtlas
                })
                
                LabeledContent("Run preload (autosaves)", content: {
                    preloadAtlasButton
                })
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            Section("Configs") {
                saveDefaultConfigButton
                resetDefaultConfigButton
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        #if os(iOS)
        .listStyle(.grouped)
        #endif
        .buttonStyle(.bordered)
        .tint(Color.primaryForeground)
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
        SGButton(fileButtonName, "") {
            setScreen(.fileBrowser)
        }
    }
    
    var downloadFromGithubButton: some View {
        SGButton(
            screen == .showGitFetch
                ? "Hide"
                : "GitHub",
            "square.and.arrow.down.fill"
        ) {
            setScreen(.showGitFetch)
        }
    }
    
    var deleteAtlas: some View {
        Button("Clear") {
            GlobalInstances.resetAtlas()
        }
    }
    
    var saveAtlasButton: some View {
        Button("Save") {
            GlobalInstances.defaultAtlas.save()
        }
    }
    
    var preloadAtlasButton: some View {
        Button("Preload") {
            GlobalInstances.defaultAtlas.preload()
        }
    }
    
    var saveDefaultConfigButton: some View {
        Button("Save Default") {
            GlobalLiveConfig.saveDefault()
        }
    }
    
    var resetDefaultConfigButton: some View {
        Button("Reset Default") {
            GlobalLiveConfig.saveDefault()
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
