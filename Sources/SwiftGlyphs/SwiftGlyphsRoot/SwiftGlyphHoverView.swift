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


public struct SwiftGlyphHoverView: View, MetalLinkReader {
    public let link: MetalLink
    @State private var currentHoveredGrid: GridPickingState.Event?
    
    @State private var mousePosition: LFloat2?
    @State private var tapPosition: LFloat2?
    
    #if os(macOS)
    @State private var modifiers = OSEvent.ModifierFlags()
    #endif

    @State private var autoJump = false
    
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
                #if os(macOS)
                modifiers = event.modifierFlags
                #endif
                
                mousePosition = event.locationInWindow.asSimd
                
            }
            .onReceive(link.input.sharedMouseDown, perform: onMouseDown(_:))
    }
    
    private func onMouseDown(_ mouseDown: OSEvent) {
        #if os(macOS)
        modifiers = mouseDown.modifierFlags
        #endif
        
        #if os(iOS)
        let hasNew = currentHoveredGrid?.newState?.targetGrid != nil
        #else
        let hasNew = currentHoveredGrid?.hasNew == true
        #endif
        
        let availableGrid = currentHoveredGrid?.newState?.targetGrid
        
        if let availableGrid {
            if hasNew {
                _ = GlobalInstances
                    .gridStore
                    .gridInteractionState
                    .bookmarkedGrids
                    .toggle(availableGrid)
            }
            
            if 
                let source = availableGrid.sourcePath
            {
                GlobalInstances.swiftGlyphRoot
                    .holder
                    .userTextInputBinding
                    .wrappedValue
                    .userSelectedFile = source
            }
        }
    }
    
    @ViewBuilder
    func rootView() -> some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading) {
                    if 
                        let hoveredState = currentHoveredGrid?.newState
                    {
                        VStack(alignment: .leading) {
                            fileNameHover(target: hoveredState.targetGrid)
                        }
                    }
                }
                .attachedToMousePosition(in: proxy, with: link)
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: .topLeading
            )
        }
    }
    
    @ViewBuilder
    var bookmarkListResizable: some View {
        ResizableComponentView(
            model: {
                AppStatePreferences.shared.getCustom(
                    name: "DragState-Hover-Glyph",
                    makeDefault: ComponentModel.init
                )
            },
            onSave: {
                AppStatePreferences.shared.setCustom(
                    name: "DragState-Hover-Glyph",
                    value: $0
                )
            },
            content: {
                bookmarkListContent
                    .padding(2)
                    .background(Color.primaryBackground.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        )
    }
    
    @ViewBuilder
    var bookmarkListContent: some View {
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
                        fileNameHover(target: grid)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func fileNameHover(
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
        HStack(alignment: .center) {
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
