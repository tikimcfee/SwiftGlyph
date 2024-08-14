//
//  ResizingControlsView.swift
//  
//
//  Created by Ivan Lugo on 8/14/24.
//

import SwiftUI

public enum ResizePoint: Codable, Equatable {
    case topLeft
    case topMiddle
    case topRight
    case rightMiddle
    case bottomRight
    case bottomMiddle
    case bottomLeft
    case leftMiddle
}

public struct ResizingControlsView: View {
    let borderColor: Color = .white
    let fillColor: Color = .blue
    let diameter: CGFloat = 15.0
    let dragged: (ResizePoint, CGFloat, CGFloat) -> Void
    let dragEnded: () -> Void
    
    public var body: some View {
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
        #if os(iOS)
        /// 'Text' is the only thing that renders.. `contentShape` doesn't work and I have no idea why.
        /// So whatever you get a square.
        return Text("⬜️")
            .offset(x: offsetX, y: offsetY)
            .gesture(dragGesture(point: resizePoint))
        #else
        return Circle()
            .strokeBorder(borderColor, lineWidth: 3)
            .background(Circle().foregroundColor(fillColor))
            .frame(width: diameter, height: diameter)
            .offset(x: offsetX, y: offsetY)
            .gesture(dragGesture(point: resizePoint))
        #endif
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
