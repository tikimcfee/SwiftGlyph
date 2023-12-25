//
//  DragSizableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

public struct DragSizableViewState: Codable, Equatable {
    public var contentBounds: CGSize = .zero
    public var offset = CGPoint(x: 0, y: 0)
    public var lastOffset = CGPoint(x: 0, y: 0)
    
    mutating func updateDrag(
        _ value: DragGesture.Value,
        _ isFinal: Bool
    ) {
        offset.x = lastOffset.x + value.translation.width
        offset.y = lastOffset.y + value.translation.height
        if isFinal {
            lastOffset = offset
        }
    }
}

public struct DragSizableModifer: ViewModifier {
    // TODO: If you sant to save window position, make this owned by the invoker
    @Binding public var state: DragSizableViewState
    public let onDragEnded: () -> Void
    
    @ViewBuilder
    public func body(content: Content) -> some View {
        rootPositionableView(content)
            .offset(x: state.offset.x, y: state.offset.y)
    }
    
    func rootPositionableView(_ wrappedContent: Content) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            dragBar
            wrappedContent
        }
        .onSizeChanged(DraggableViewSize.self) {
            guard state.contentBounds != $0 else { return }
            state.contentBounds = $0
        }
        #if os(iOS)
        // TODO: Why doesn't it work on iOS?
        .gesture(DragGesture(
            minimumDistance: 2,
            coordinateSpace: .global
        ).onChanged { value in
            state.updateDrag(value, false)
        }.onEnded { value in
            state.updateDrag(value, true)
        })
        #endif
    }
    
    var dragBar: some View {
        Color.gray.opacity(0.4)
            .frame(maxWidth: state.contentBounds.width, maxHeight: 12)
            .highPriorityGesture(
                DragGesture(
                    minimumDistance: 2,
                    coordinateSpace: .global
                )
                .onChanged { value in
                    state.updateDrag(value, false)
                }
                .onEnded { value in
                    state.updateDrag(value, true)
                    onDragEnded()
                }
            )
            .contentShape(Rectangle())
    }
}
