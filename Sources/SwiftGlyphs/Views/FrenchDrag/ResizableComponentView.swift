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
    
    let displayMode: Binding<FloatableViewMode>
    let windowKey: GlobalWindowKey
    
    let onSave: (ComponentModel) -> Void
    @ViewBuilder let content: () -> Content
    
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
        GeometryReader { proxy in
            ZStack {
                dragBarContentStack(proxy)
                resizingControlsOverlay(proxy)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(
                width: model.widthForCardComponent(),
                height: model.heightForCardComponent()
            )
            .position(
                x: model.xPositionForCardComponent(),
                y: model.yPositionForCardComponent()
            )
        }
    }
    
    @ViewBuilder
    func resizingControlsOverlay(_ proxy: GeometryProxy) -> some View {
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
        
    @ViewBuilder
    func dragBarContentStack(_ proxy: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            dragBarWithAttachedGestures(proxy)
            content()
        }
    }
        
    @ViewBuilder
    var dragBarOverlay: some View {
        #if os(macOS)
        if displayMode.wrappedValue == .displayedAsSibling
        {
            SwitchModeButtons(
                displayMode: displayMode,
                windowKey: windowKey
            )
            .padding(4)
        }
        #else
        SwitchModeButtonsMobile(
            displayMode: displayMode,
            windowKey: windowKey
        )
        .padding(4)
        #endif
    }
    
    func dragBarWithAttachedGestures(_ proxy: GeometryProxy) -> some View {
        dragBar
            .frame(maxWidth: .infinity, maxHeight: 24)
            .overlay() {
                ZStack(alignment: .center) {
                    HStack {
                        dragBarOverlay
                        Spacer()
                    }
                    
                    Text(windowKey.rawValue)
                }
                .gesture(dragGesture(proxy))
                .onTapGesture(count: 2, perform: {
                    isResizing.toggle()
                })
            }
            .gesture(dragGesture(proxy))
            .onTapGesture(count: 2, perform: {
                isResizing.toggle()
            })
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
    }
    
    func dragGesture(_ proxy: GeometryProxy) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { gesture in
                print("drag:", gesture.location, "size:", proxy.size, proxy.safeAreaInsets)
                if gesture.location.y <= (proxy.safeAreaInsets.top + 8) { return }
                
                let halfWidth = model.widthForCardComponent() / 4
                if gesture.translation.width + model.xPositionForCardComponent() + halfWidth > proxy.size.width {
                    return
                }
                
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
