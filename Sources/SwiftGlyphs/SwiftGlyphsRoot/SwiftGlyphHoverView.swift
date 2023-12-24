//  
//
//  Created on 12/17/23.
//  

#if os(iOS)
import ARKit
#endif
import SwiftUI
import MetalLink
import BitHandling

struct AtMousePositionModifier: ViewModifier {
    public let link: MetalLink
    public let cursorOffset: CGFloat = 24.0
    
    var proxy: GeometryProxy
    @State var mousePosition: LFloat2?
    
    func body(content: Content) -> some View {
        content.onReceive(link.input.sharedMouse) { event in
            mousePosition = event.locationInWindow.asSimd
        }.offset(
            mousePosition.map {
                CGSize(
                    width: $0.x.cg + cursorOffset,
                    height: proxy.size.height - $0.y.cg - cursorOffset
                )
            } ?? CGSizeZero
        )
    }
}

extension View {
    func attachedToMousePosition(
        in parentProxy: GeometryProxy,
        with link: MetalLink
    ) -> some View {
        modifier(AtMousePositionModifier(
            link: link,
            proxy: parentProxy
        ))
    }
}

public struct SwiftGlyphHoverView: View, MetalLinkReader {
    public let link: MetalLink
    @State private var currentHoveredGrid: GridPickingState.Event?
    
    @State private var mousePosition: LFloat2?
    @State private var tapPosition: LFloat2?
    @State private var modifiers = OSEvent.ModifierFlags()

    @State private var autoJump = false
    @State private var dragState = DragSizableViewState()
    
    public init(link: MetalLink) {
        self.link = link
    }
    
    // We assume we take up the same size as the parent
    public var body: some View {
        rootView()
            .onReceive(
                GlobalInstances.gridStore
                    .nodeHoverController
                    .sharedGridEvent
                    .subscribe(on: RunLoop.main)
                    .receive(on: RunLoop.main),
                perform: { hoveredGrid in
                    self.currentHoveredGrid = hoveredGrid
                }
            )
            .onReceive(link.input.sharedMouse) { event in
                mousePosition = event.locationInWindow.asSimd
                modifiers = event.modifierFlags
            }
            .onReceive(link.input.sharedMouseDown) { mouseDown in
                let hasNew = currentHoveredGrid?.hasNew == true
                let availableGrid = currentHoveredGrid?.newState?.targetGrid
                
                if hasNew, let availableGrid {
                    _ = GlobalInstances
                        .gridStore
                        .gridInteractionState
                        .bookmarkedGrids
                        .toggle(availableGrid)
                }
            }
    }
    
    @ViewBuilder
    func rootView() -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {  // weirdly, this is overridden by the frame.
                VStack(alignment: .leading) {
                    if let hoveredState = currentHoveredGrid?.newState {
                        VStack(alignment: .leading) {
                            gridInfoList(target: hoveredState.targetGrid)
                        }
                    }
                }.attachedToMousePosition(in: proxy, with: link)
                
                bookmarkList()
                    .padding(2)
                    .background(Color.primaryBackground.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .modifier(
                        DragSizableModifer(state: $dragState) {
                            AppStatePreferences.shared.setCustom(
                                name: "DragState-Hover-Glyph",
                                value: dragState
                            )
                        }

                    )
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: .topLeading // this overrides the z-stack alignment.
            )
        }
        
    }
    
    @ViewBuilder
    func bookmarkList() -> some View {
        
        if GlobalInstances.gridStore.gridInteractionState.bookmarkedGrids.isEmpty {
            Text("No Bookmarks").bold().padding()
        } else {
            let bookmarks = GlobalInstances
                .gridStore
                .gridInteractionState
                .bookmarkedGrids
            
            VStack(alignment: .leading, spacing: 2) {
                ForEach(bookmarks, id: \.id) { grid in
                    HStack(alignment: .top) {
                        gridOptionList(target: grid)
                        gridInfoList(target: grid)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func gridInfoList(
        target grid: CodeGrid
    ) -> some View {
        VStack(alignment: .leading) {
            Text(grid.fileName)
                .font(.headline)
                .bold()
        }
        .padding(4)
        .background(Color.primaryBackground.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    @ViewBuilder
    func gridOptionList(
        target grid: CodeGrid
    ) -> some View {
        HStack(alignment: .center, spacing: 2) {
            SGButton("Jump", "") {
                GlobalInstances.debugCamera.interceptor.resetPositions()
                GlobalInstances.debugCamera.position = grid.worldPosition.translated(dZ: 64)
                GlobalInstances.debugCamera.rotation = .zero
            }
            
            SGButton("-", "") {
                GlobalInstances
                    .gridStore
                    .gridInteractionState
                    .bookmarkedGrids
                    .removeAll(where: { $0.id == grid.id })
            }
        }
        .padding(4)
        .background(Color.primaryBackground.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
