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
    
    @State private var bookmarkedGrids: Set<CodeGrid> = []
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
                    if tapPosition != nil { return }
                    self.currentHoveredGrid = hoveredGrid
                }
            )
            .onReceive(link.input.sharedMouse) { event in
                mousePosition = event.locationInWindow.asSimd
            }
            .onReceive(link.input.sharedMouseDown) { mouseDown in
                let hasNew = currentHoveredGrid?.hasNew == true
                let availableGrid = currentHoveredGrid?.newState?.targetGrid
                if autoJump, hasNew, let grid = availableGrid {
                    GlobalInstances.debugCamera.interceptor.resetPositions()
                    GlobalInstances.debugCamera.position = grid.worldPosition.translated(dZ: 64)
                    GlobalInstances.debugCamera.rotation = .zero
                } else {
                    if mouseDown.modifierFlags.contains(.command) {
                        if tapPosition != nil {
                            tapPosition = nil
                            
                            if mouseDown.modifierFlags.contains(.shift) {
                                GlobalInstances.gridStore
                                    .nodeHoverController
                                    .lastGridEvent = .notFound
                            }
                        } else {
                            tapPosition = mouseDown.locationInWindow.asSimd
                        }
                    }
                }
                if hasNew, let availableGrid {
                    _ = bookmarkedGrids.toggle(availableGrid)
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
                    } else {
                        Text("...")
                            .padding(2)
                            .background(Color.primaryBackground.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    }
                    
                    bookmarkList()
                        .padding(2)
                        .background(Color.primaryBackground.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding([.leading], 24)
                .offset(
                    (tapPosition ?? mousePosition).map {
                        CGSize(width: $0.x.cg, height: proxy.size.height - $0.y.cg)
                    } ?? CGSizeZero
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
        // TODO: I know, I know; performace, list, arrays, slow, etc. etc.
        let bookmarks = Array(bookmarkedGrids).sorted(by: { $0.fileName < $1.fileName})
        VStack(alignment: .leading, spacing: 2) {
            ForEach(bookmarks, id: \.id) { grid in
                HStack(alignment: .top) {
                    gridOptionList(target: grid)
                    gridInfoList(target: grid)
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
            
//            if let path = grid.sourcePath {
//                let slices = path.pathComponents.suffix(10).slices(sliceSize: 5)
//                ForEach(slices, id: \.startIndex) { slice in
//                    HStack(spacing: 0) {
//                        ForEach(slice, id: \.self) { component in
//                            Text(component)
//                                .font(.footnote)
//                                .foregroundStyle(.secondary)
//                            Text("/")
//                                .font(.footnote)
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                }
//                .padding(2)
//                .background(Color.primaryBackground.opacity(0.1))
//                .clipShape(RoundedRectangle(cornerRadius: 8))
//            }
        }
        .padding(4)
        .background(Color.primaryBackground.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 2))
        .padding()
    }

    @ViewBuilder
    func gridOptionList(
        target grid: CodeGrid
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            SGButton("Jump", "") {
                GlobalInstances.debugCamera.interceptor.resetPositions()
                GlobalInstances.debugCamera.position = grid.worldPosition.translated(dZ: 64)
                GlobalInstances.debugCamera.rotation = .zero
            }
            
            if bookmarkedGrids.contains(grid) {
                SGButton("Remove Bookmark", "") {
                    bookmarkedGrids.remove(grid)
                }
            } else {
                SGButton("Bookmark", "") {
                    bookmarkedGrids.insert(grid)
                }
            }
        }
        .padding(4)
        .background(Color.primaryBackground.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
