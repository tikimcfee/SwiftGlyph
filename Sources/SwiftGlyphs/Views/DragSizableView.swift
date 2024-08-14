//
//  DragSizableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI
import BitHandling

extension View {
    func withSavedDragstate(
        named name: String,
        _ dragState: Binding<DragSizableViewState>
    ) -> some View {
        modifier(
            DragSizableModifier(state: dragState) {
                AppStatePreferences.shared
                    .setCustom(
                        name: name,
                        value: dragState.wrappedValue
                    )
            }
        ).onAppear {
            dragState.wrappedValue =
                AppStatePreferences.shared
                    .getCustom(
                        name: name,
                        makeDefault: {
                            DragSizableViewState()
                        }
                    )
        }
    }
}

public struct DragSizableViewState: Codable, Equatable {
    public var contentBounds: CGSize = .zero
    public var offset = CGPoint(x: 0, y: 0)
    public var lastOffset = CGPoint(x: 0, y: 0)
    public var topBar = true
    
    mutating func updateDrag(
        parentSize: CGSize,
        _ value: DragGesture.Value,
        _ isFinal: Bool
    ) {
//        guard parentSize.width > .zero else { return }
//        guard parentSize.height > .zero else { return }
//        
//        let window = GlobalWindowDelegate.instance.rootWindow?.frame
//        let clampX = clamp(
//            lastOffset.x + value.translation.width,
//            min: -(parentSize.width / 2),
//            max: (window?.width ?? .infinity) - (parentSize.width / 2)
//        )
//        let clampY = clamp(
//            lastOffset.y + value.translation.height,
//            min: 0,
//            max: (window?.height ?? .infinity) - 40
//        )
//        offset.x = clampX
//        offset.y = clampY
        
        offset.x = lastOffset.x + value.translation.width
        offset.y = lastOffset.y + value.translation.height
        
        if isFinal {
            lastOffset = offset
        }
    }
}

public struct DragSizableModifier: ViewModifier {
    // TODO: If you sant to save window position, make this owned by the invoker
    @Binding public var state: DragSizableViewState
    @State public var isHovered: Bool = false
    public let onDragEnded: () -> Void
    public let enabled: Bool
    
    init(
        state: Binding<DragSizableViewState>,
        enabled: Bool = true,
        onDragEnded: @escaping () -> Void
    ) {
        self._state = state
        self.enabled = enabled
        self.onDragEnded = onDragEnded
    }
    
    @ViewBuilder
    public func body(content: Content) -> some View {
        if !enabled {
            content
        } else {
            rootPositionableView(content)
                .offset(x: state.offset.x, y: state.offset.y)
        }
    }
    
    func rootPositionableView(_ wrappedContent: Content) -> some View {
        ResizableView {
            VStack(alignment: .trailing, spacing: 2) {
                if state.topBar { dragBar }
                wrappedContent
            }
        }
        .onSizeChanged(DraggableViewSize.self) {
            guard state.contentBounds != $0 else { return }
            state.contentBounds = $0
        }
    }
    
    var dragBar: some View {
        GeometryReader { reader in
            Color.gray
                .frame(maxWidth: state.contentBounds.width, maxHeight: 20)
                .padding(.bottom, 8) // I have no idea why the hover / drag effect is off visually.. but here's a hack
                .padding(.top, -2)
                .opacity(isHovered ? 0.8 : 0.4)
                .onHover { isHovered = $0 }
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(
                        minimumDistance: 2,
                        coordinateSpace: .global
                    )
                    .onChanged { value in
                        state.updateDrag(parentSize: reader.size, value, false)
                    }
                    .onEnded { value in
                        state.updateDrag(parentSize: reader.size, value, true)
                        onDragEnded()
                    }
                )
        }
    }
}


struct ResizableView<Content: View>: View {
    @State private var size: CGSize = CGSize(width: 400, height: 500)
    @State public var isHovered: Bool = false
    
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            content.frame(
                width: size.width,
                height: size.height
            )
            .padding(.bottom, 20)
            resizeHandle
        }
    }
    
    private var resizeHandle: some View {
        Rectangle()
            .fill(Color.gray.opacity(isHovered ? 0.8 : 0.4))
            .frame(width: 10, height: 10)
            .cornerRadius(10)
            .padding([.leading, .bottom, .trailing], 5)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        size.width = clamp(value.translation.width + size.width, min: 100, max: 1200)
                        size.height = clamp(value.translation.height + size.height, min: 100, max: 1200)
                        print(size)
                    }
            )
            .onHover { isHovered = $0 }
    }
}

func clamp<T: Comparable>(_ value: T, min minIn: T, max maxIn: T) -> T {
    max(min(maxIn, value), minIn)
}
