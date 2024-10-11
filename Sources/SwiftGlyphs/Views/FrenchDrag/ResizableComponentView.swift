///
/// Sourced from, and with thanks to:
/// https://github.com/Kevin-French/Resizing_ProblemApp
///
/// Modified by Ivan Lugo
///

import SwiftUI

struct ResizableComponentViewModifer: ViewModifier {
    let savedStateName: String
    
    func body(content: Content) -> some View {
        content
    }
}

public struct ResizableComponentView<Content: View>: View {
    
    @State var isHovered: Bool = false
    @State var model: ComponentModel
    @State var isResizing: Bool = false
    
    let displayMode: Binding<FloatableViewMode>?
    let windowKey: GlobalWindowKey?
    
    let onSave: (ComponentModel) -> Void
    @ViewBuilder let content: () -> Content
        
    public init(
        model: @escaping () -> ComponentModel,
        onSave: @escaping (ComponentModel) -> Void,
        content: @escaping () -> Content
    ) {
        self._model = State(wrappedValue: model())
        self.onSave = onSave
        self.content = content
        self.displayMode = nil
        self.windowKey = nil
    }    
    
    public init(
        displayMode: Binding<FloatableViewMode>,
        windowKey: GlobalWindowKey,
        model: @escaping () -> ComponentModel,
        onSave: @escaping (ComponentModel) -> Void,
        content: @escaping () -> Content
    ) {
        self._model = State(wrappedValue: model())
        self.onSave = onSave
        self.content = content
        self.displayMode = displayMode
        self.windowKey = windowKey
    }
    
    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                dragBar
                    .frame(maxWidth: .infinity, maxHeight: 28)
                    .overlay(alignment: .leading) {
                        dragBarOverlay
                    }

                content()
            }
            ResizingControlsView(
                isResizing: $isResizing
            ) { point, deltaX, deltaY in
                model.updateForResize(using: point, deltaX: deltaX, deltaY: deltaY)
                onSave(model)
            } dragEnded: {
                model.resizeEnded()
                onSave(model)
            }
        }
        .frame(
            width: model.widthForCardComponent(),
            height: model.heightForCardComponent()
        )
        .position(
            x: model.xPositionForCardComponent(),
            y: model.yPositionForCardComponent()
        )
    }
    
    @ViewBuilder
    var dragBarOverlay: some View {
        if let displayMode, let windowKey,
           displayMode.wrappedValue == .displayedAsSibling
        {
            SwitchModeButtons(
                displayMode: displayMode,
                windowKey: windowKey
            )
            .padding(4)
        }
    }
    
    var dragBar: some View {
        Color.gray
            .opacity(isHovered ? 0.5 : 0.4)
            .onHover { hovered in
                withAnimation(.easeInOut(duration: 1 / 12)) {
                    isHovered = hovered
                }
            }
            .contentShape(Rectangle())
            .gesture(dragGesture)
            .onTapGesture(count: 2, perform: {
                isResizing.toggle()
            })
    }
    
    var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { gesture in
                model.updateForDrag(
                    deltaX: gesture.translation.width,
                    deltaY: gesture.translation.height
                )
                onSave(model)
            }
            .onEnded { _ in
                model.dragEnded()
                onSave(model)
            }
    }
}
