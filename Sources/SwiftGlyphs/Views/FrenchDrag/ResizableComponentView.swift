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
    }
    
    public var body: some View {
        ZStack {
            VStack {
                dragBar
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
    
    var dragBar: some View {
        Color.gray
            .frame(maxWidth: .infinity, maxHeight: 20)
            .opacity(isHovered ? 0.8 : 0.4)
            .onHover { isHovered = $0 }
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
