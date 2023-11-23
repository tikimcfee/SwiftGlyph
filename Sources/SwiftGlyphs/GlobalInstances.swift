//
//  GlobalInstances.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/28/22.
//
// ------------------------------------------------------------------------------------
// I realize all this instance stuff is bad joojoo. Everything talks to everything else.
// However, I'm moving things around a lot right now and experimenting with placement and
// hierarchy. I'd rather have more concrete working stuff in place first.
// ------------------------------------------------------------------------------------
//
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// A short term plan for this is, when things get dicey, to setup a 'getInstance(for: self)`
// intance locator that figure this stuff out. Or get a dependency locator library. Either's fine.
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//

import Foundation
import Combine
import Metal
import MetalLink
import MetalLinkHeaders
import BitHandling

public class GlobalInstances {
    private init () { }
}

// MARK: - App State
// ______________________________________________________________
public extension GlobalInstances {
    static let appStatus = AppStatus()
    static let _2ETRoot = try! TwoETimeRoot(link: defaultLink)
}


// MARK: - Files
// ______________________________________________________________
public extension GlobalInstances {
    static let fileBrowser = FileBrowser()
    static let fileStream = fileBrowser.$scopes.share().eraseToAnyPublisher()
    static let fileEventStream = fileBrowser.$fileSelectionEvents.share().eraseToAnyPublisher()
}


// MARK: - Metal
// ______________________________________________________________
public extension GlobalInstances {
    static let rootCustomMTKView: CustomMTKView = makeRootCustomMTKView()
    static let defaultLink: MetalLink = makeDefaultLink()
    static let defaultRenderer: MetalLinkRenderer = makeDefaultRenderer()
    static let defaultAtlas: MetalLinkAtlas = makeDefaultAtlas()
    
    private static func makeRootCustomMTKView() -> CustomMTKView {
        CustomMTKView(frame: .zero, device: MTLCreateSystemDefaultDevice())
    }
    
    private static func makeDefaultLink() -> MetalLink {
        return try! MetalLink(view: rootCustomMTKView)
    }
    
    private static func makeDefaultAtlas() -> MetalLinkAtlas {
        return try! MetalLinkAtlas(defaultLink)
    }
    
    private static func makeDefaultRenderer() -> MetalLinkRenderer {
        return try! MetalLinkRenderer(link: defaultLink)
    }
    
    static func createDefaultMetalView() -> MetalView {
        MetalView(
            mtkView: rootCustomMTKView,
            link: defaultLink,
            renderer: defaultRenderer
        )
    }
}


// MARK: - Grids
// ______________________________________________________________
public extension GlobalInstances {
    static let gridStore = GridStore()
}

// MARK: - Debug
public extension GlobalInstances {
    static let debugCamera = DebugCamera(link: defaultLink)
}

// MARK: - Shared Workers and caches
// ______________________________________________________________
public class GridStore {
    private var link: MetalLink { GlobalInstances.defaultLink }
    public private(set) lazy var globalTokenCache: CodeGridTokenCache = CodeGridTokenCache()
    public private(set) lazy var globalSemanticMap: SemanticInfoMap = SemanticInfoMap()
    
    public private(set) lazy var gridCache: GridCache = GridCache(tokenCache: globalTokenCache)
    public private(set) lazy var concurrentRenderer: ConcurrentGridRenderer = ConcurrentGridRenderer(cache: gridCache)
    public private(set) lazy var globalSemantics: CodeGridGlobalSemantics = CodeGridGlobalSemantics(source: gridCache)
    
    public private(set) lazy var searchContainer: SearchContainer = SearchContainer(gridCache: gridCache)
    public private(set) lazy var nodeHoverController: MetalLinkHoverController = MetalLinkHoverController(link: link)
    public private(set) lazy var gridInteractionState: GridInteractionState = GridInteractionState(
        hoverController: nodeHoverController,
        input: DefaultInputReceiver.shared
    )
    public private(set) lazy var editor: WorldGridEditor = WorldGridEditor()
    
    public private(set) lazy var worldFocusController: WorldGridFocusController = WorldGridFocusController(
        link: link,
        camera: GlobalInstances.debugCamera,
        editor: editor
    )
    
    public private(set) lazy var nodeFocusController: CodeGridSelectionController = CodeGridSelectionController(
        tokenCache: globalTokenCache
    )
}
