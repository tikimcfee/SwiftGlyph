///
/// Sourced from, and with thanks to:
/// https://github.com/Kevin-French/Resizing_ProblemApp
///
/// Modified by Ivan Lugo
///

import SwiftUI

struct ResizableComponentView<Content: View>: View {
    
    @State var isHovered: Bool = false
    @State var model: ComponentModel = ComponentModel()
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ZStack {
            VStack {
                dragBar
                content()
            }
            ResizingControlsView { point, deltaX, deltaY in
                model.updateForResize(using: point, deltaX: deltaX, deltaY: deltaY)
            } dragEnded: {
                model.resizeEnded()
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
            .gesture( dragGesture )
    }
    
    var dragGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { gesture in
                model.updateForDrag(
                    deltaX: gesture.translation.width,
                    deltaY: gesture.translation.height
                )
            }
            .onEnded { _ in
                model.dragEnded()
            }
    }
}

struct ComponentState {
    var origin: CGPoint
    var size: CGSize

    init(
        origin: CGPoint = .zero,
        size: CGSize = .init(width: 300, height: 300)
    ) {
        self.origin = origin
        self.size = size
    }
}

struct ComponentModel {
    var componentInfo = ComponentState()
    var dragOffset: CGSize? = nil
    var resizeOffset: CGSize? = nil
    var resizePoint: ResizePoint? = nil

    func widthForCardComponent() -> CGFloat {
        let widthOffset = resizeOffset?.width ?? 0.0
        return componentInfo.size.width + widthOffset
    }
    
    func heightForCardComponent() -> CGFloat {
        let heightOffset = resizeOffset?.height ?? 0.0
        return componentInfo.size.height + heightOffset
    }
    
    func xPositionForCardComponent() -> CGFloat {
        let xPositionOffset = dragOffset?.width ?? 0.0
        return componentInfo.origin.x 
            + (componentInfo.size.width / 2.0)
            + xPositionOffset
    }
    
    func yPositionForCardComponent() -> CGFloat {
        let yPositionOffset = dragOffset?.height ?? 0.0
        return componentInfo.origin.y 
            + (componentInfo.size.height / 2.0)
            + yPositionOffset
    }
    
    mutating func resizeEnded() {
        guard let resizePoint, let resizeOffset else { return }
        
        var w: CGFloat = componentInfo.size.width
        var h: CGFloat = componentInfo.size.height
        var x: CGFloat = componentInfo.origin.x
        var y: CGFloat = componentInfo.origin.y
        switch resizePoint {
        case .topLeft:
            w -= resizeOffset.width
            h -= resizeOffset.height
            x += resizeOffset.width
            y += resizeOffset.height
        case .topMiddle:
            h -= resizeOffset.height
            y += resizeOffset.height
        case .topRight:
            w += resizeOffset.width
            h -= resizeOffset.height
        case .rightMiddle:
            w += resizeOffset.width
        case .bottomRight:
            w += resizeOffset.width
            h += resizeOffset.height
        case .bottomMiddle:
            h += resizeOffset.height
        case .bottomLeft:
            w -= resizeOffset.width
            h += resizeOffset.height
            x -= resizeOffset.width
            y += resizeOffset.height
        case .leftMiddle:
            w -= resizeOffset.width
            x += resizeOffset.width
        }
        componentInfo.size = CGSize(width: w, height: h)
        componentInfo.origin = CGPoint(x: x, y: y)
        self.resizeOffset = nil
        self.resizePoint = nil
    }
    
    mutating func updateForDrag(deltaX: CGFloat, deltaY: CGFloat) {
        dragOffset = CGSize(width: deltaX, height: deltaY)
    }
    
    mutating func dragEnded() {
        guard let dragOffset else { return }
        componentInfo.origin.x += dragOffset.width
        componentInfo.origin.y += dragOffset.height
        self.dragOffset = nil
    }
    
    mutating func updateForResize(using resizePoint: ResizePoint, deltaX: CGFloat, deltaY: CGFloat) {
        var width: CGFloat = componentInfo.size.width
        var height: CGFloat = componentInfo.size.height
        var x: CGFloat = componentInfo.origin.x
        var y: CGFloat = componentInfo.origin.y
        switch resizePoint {
        case .topLeft:
            width -= deltaX
            height -= deltaY
            x += deltaX
            y += deltaY
        case .topMiddle:
            height -= deltaY
            y += deltaY
        case .topRight:
            width += deltaX
            height -= deltaY
            y += deltaY
        case .rightMiddle:
            width += deltaX
        case .bottomRight:
            width += deltaX
            height += deltaY
        case .bottomMiddle:
            height += deltaY
        case .bottomLeft: //
            width -= deltaX
            height += deltaY
            x += deltaX
        case .leftMiddle:
            width -= deltaX
            x += deltaX
        }
        componentInfo.size = CGSize(width: width, height: height)
        componentInfo.origin = CGPoint(x: x, y: y)
    }
}

enum ResizePoint {
    case topLeft
    case topMiddle
    case topRight
    case rightMiddle
    case bottomRight
    case bottomMiddle
    case bottomLeft
    case leftMiddle
}

struct ResizingControlsView: View {
    let borderColor: Color = .white
    let fillColor: Color = .blue
    let diameter: CGFloat = 15.0
    let dragged: (ResizePoint, CGFloat, CGFloat) -> Void
    let dragEnded: () -> Void
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack(spacing: 0.0) {
                grabView(resizePoint: .topLeft)
                Spacer()
                grabView(resizePoint: .topMiddle)
                Spacer()
                grabView(resizePoint: .topRight)
            }
            Spacer()
            HStack(spacing: 0.0) {
                grabView(resizePoint: .leftMiddle)
                Spacer()
                grabView(resizePoint: .rightMiddle)
            }
            Spacer()
            HStack(spacing: 0.0) {
                grabView(resizePoint: .bottomLeft)
                Spacer()
                grabView(resizePoint: .bottomMiddle)
                Spacer()
                grabView(resizePoint: .bottomRight)
            }
        }
    }
    
    private func grabView(resizePoint: ResizePoint) -> some View {
        var offsetX: CGFloat = 0.0
        var offsetY: CGFloat = 0.0
        let halfDiameter = diameter / 2.0
        switch resizePoint {
        case .topLeft:
            offsetX = -halfDiameter
            offsetY = -halfDiameter
        case .topMiddle:
            offsetY = -halfDiameter
        case .topRight:
            offsetX = halfDiameter
            offsetY = -halfDiameter
        case .rightMiddle:
            offsetX = halfDiameter
        case .bottomRight:
            offsetX = +halfDiameter
            offsetY = halfDiameter
        case .bottomMiddle:
            offsetY = halfDiameter
        case .bottomLeft:
            offsetX = -halfDiameter
            offsetY = halfDiameter
        case .leftMiddle:
            offsetX = -halfDiameter
        }
        return Circle()
            .strokeBorder(borderColor, lineWidth: 3)
            .background(Circle().foregroundColor(fillColor))
            .frame(width: diameter, height: diameter)
            .offset(x: offsetX, y: offsetY)
            .gesture(dragGesture(point: resizePoint))
    }
    
    private func dragGesture(point: ResizePoint) -> some Gesture {
        DragGesture()
            .onChanged { drag in
                switch point {
                case .topLeft:
                    dragged(point, drag.translation.width, drag.translation.height)
                case .topMiddle:
                    dragged(point, 0, drag.translation.height)
                case .topRight:
                    dragged(point, drag.translation.width, drag.translation.height)
                case .rightMiddle:
                    dragged(point, drag.translation.width, 0)
                case .bottomRight:
                    dragged(point, drag.translation.width, drag.translation.height)
                case .bottomMiddle:
                    dragged(point, 0, drag.translation.height)
                case .bottomLeft:
                    dragged(point, drag.translation.width, drag.translation.height)
                case .leftMiddle:
                    dragged(point, drag.translation.width, 0)
                }
            }
            .onEnded { _ in dragEnded() }
    }
}
