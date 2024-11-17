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
            
            floatingControlToggles
            
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
    var conditionalControls: some View {
        if showControls {
            AppControlPanelView()
        }
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

public enum SGButtonStyle {
    case toolbar
    case medium
    case small
    
    var padding: EdgeInsets {
        switch self {
        case .toolbar: return .init(top: 6, leading: 8, bottom: 6, trailing: 8)
        case .medium: return .init(top: 4, leading: 4, bottom: 4, trailing: 4)
        case .small: return .init(top: 1, leading: 4, bottom: 1, trailing: 4)
        }
    }
}

public func SGButton(
    _ text: String,
    _ image: String,
    _ style: SGButtonStyle = .small,
    _ action: @escaping () -> Void
) -> some View {
    Button(
        action: action,
        label: {
            HStack {
                if !text.isEmpty {
                    Text(text)
                        .font(.caption2)
                }
                
                if !image.isEmpty {
                    Image(systemName: image)
                }
            }
            .padding(style.padding)
            .background(Color.primarySGButtonBackground)
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
