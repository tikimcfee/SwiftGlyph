//  
//
//  Created on 12/16/23.
//  

import SwiftUI

struct ResizableDraggableModifier: ViewModifier {
    @State private var width: CGFloat = 320
    @State private var height: CGFloat = 320
    @State private var offset: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .frame(minWidth: width, minHeight: height)
            .offset(offset)
            .overlay(dragOverlay)
    }
    
    @ViewBuilder
    func topDragBar(_ geometry: GeometryProxy) -> some View {
        // Top Drag Bar
        Rectangle()
            .frame(width: geometry.size.width, height: 30)
            .opacity(0.01)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        self.offset.width += gesture.translation.width
                        self.offset.height += gesture.translation.height
                    }
            )
    }
    
    func cornerDragGesture(_ corner: Corner) -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                let translation = gesture.translation
                switch corner {
                case .topLeft:
                    self.width -= translation.width
                    self.height -= translation.height
                    self.offset.width += translation.width
                    self.offset.height += translation.height
                case .topRight:
                    self.width += translation.width
                    self.height -= translation.height
                    self.offset.height += translation.height
                case .bottomLeft:
                    self.width -= translation.width
                    self.height += translation.height
                    self.offset.width += translation.width
                case .bottomRight:
                    self.width += translation.width
                    self.height += translation.height
                }
            }
    }
    
    @ViewBuilder
    func cornerBuilder(_ geometry: GeometryProxy) -> some View {
        // Corner drag points
        ForEach(Corner.allCases, id: \.self) { corner in
            Circle()
                .frame(width: 30, height: 30)
                .opacity(0.01)
                .position(corner.position(in: geometry.size))
                .gesture(cornerDragGesture(corner))
        }
    }

    @ViewBuilder
    var dragOverlay: some View {
        GeometryReader { geometry in
            topDragBar(geometry)
            cornerBuilder(geometry)
        }
    }
}

extension View {
    func resizableAndDraggable() -> some View {
        self.modifier(ResizableDraggableModifier())
    }
}

enum Corner: CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight

    func position(in size: CGSize) -> CGPoint {
        switch self {
        case .topLeft:
            return CGPoint(x: 15, y: 15)
        case .topRight:
            return CGPoint(x: size.width - 15, y: 15)
        case .bottomLeft:
            return CGPoint(x: 15, y: size.height - 15)
        case .bottomRight:
            return CGPoint(x: size.width - 15, y: size.height - 15)
        }
    }
}
