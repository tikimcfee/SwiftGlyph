//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/19/24.
//

import SwiftUI
import BitHandling
import MetalLink

private let BookmarkListViewStateName = "DragState-Bookmark-List-View"

struct BookmarkListView: View {
//    @State var hoveredGrid: GridPickingState.Event?
//    @State var hoveredNode: NodePickingState.Event?
    @State var expandedGrids: Set<CodeGrid.ID> = []
    
    var body: some View {
        bookmarkListResizable
//            .attachedHoverState($hoveredGrid, $hoveredNode)
            #if os(iOS)
            .frame(minWidth: 300)
            #endif
    }
    
    @ViewBuilder
    var bookmarkListResizable: some View {
        bookmarkListContent
            .padding(2)
            .background(Color.primaryBackground.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    var bookmarkListContent: some View {
        if GlobalInstances.gridStore.gridInteractionState.bookmarkedGrids.isEmpty {
            Text("No Bookmarks")
                .bold()
                .padding(.horizontal)
            
            Text("Open a file and click it to bookmark.")
                .font(.caption2)
                .padding(.horizontal)
                
        } else {
            let bookmarks = GlobalInstances
                .gridStore
                .gridInteractionState
                .bookmarkedGrids
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(bookmarks.reversed(), id: \.id) { grid in
                    VStack(spacing: 2) {
                        gridRow(grid)
                            .padding(.horizontal, 4)
                        Divider()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    func gridRow(_ grid: CodeGrid) -> some View {
        VStack {
            HStack {
                Text(grid.fileName)
                
                Spacer()
                
                gridOptionList(target: grid)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                expandedGrids.toggle(grid.id)
            }
            
            if grid.sliderBinding_canShowRenderSlider {
                expandedGridOptions(grid)
            }
        }
    }
    
    @ViewBuilder
    func expandedGridOptions(_ grid: CodeGrid) -> some View {
        VStack {
            TextField(
                "Max Character Count",
                value: Binding(
                    get: {
                        grid.rootNode.instanceState.maxRenderCount
                    },
                    set: {
                        grid.rootNode.instanceState.maxRenderCount = clamp(
                            $0,
                            min: 1,
                            max: grid.rootNode.instanceState.instanceBufferCount
                        )
                    }
                ),
                formatter: NumberFormatter.integerFormatter
            )
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
//
  
            if grid.sliderBinding_canShowRenderSlider {
                Slider(
                    value: grid.sliderBinding_baseRenderIndex,
                    in: grid.sliderBinding_Range,
                    step: grid.sliderBinding_step,
                    label: {
                        Text("Render from: \(grid.rootNode.instanceState.baseRenderIndex)")
                    },
                    minimumValueLabel: {
                        Text("0")
                    },
                    maximumValueLabel: {
                        Text("\(grid.rootNode.instanceState.instanceBufferCount)")
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    func gridOptionList(
        target grid: CodeGrid
    ) -> some View {
        HStack(alignment: .center) {
            SGButton("Show", "scope") {
                grid.displayFocused(GlobalInstances.debugCamera)
            }
            
            SGButton("", "xmark") {
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

extension NumberFormatter {
    static var integerFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none // No formatting (pure integer input)
        formatter.allowsFloats = false // Prevents floats
        return formatter
    }
}

extension CodeGrid {
    var sliderBinding_canShowRenderSlider: Bool {
        rootNode.instanceState.instanceBufferCount >= GlobalLiveConfig.Default.maxInstancesPerGrid
    }
    
    var sliderBinding_step: Float {
        clamp(
            GlobalLiveConfig.Default.maxInstancesPerGrid.float / 1.167,
            min: 1,
            max: self.rootNode.instanceState.instanceBufferCount.float
        )
    }
    
    var sliderBinding_baseRenderIndex: Binding<Float> {
        Binding(
            get: { self.rootNode.instanceState.baseRenderIndex.float },
            set: { self.rootNode.instanceState.baseRenderIndex = Int($0) }
        )
    }
    
    var sliderBinding_Range: ClosedRange<Float> {
        let state = rootNode.instanceState
        let rangeMax = state.instanceBufferCount.float
        let clampedMax = clamp(rangeMax, min: 0.0, max: state.instanceBufferCount.float)
        return (0...clampedMax)
    }
}
