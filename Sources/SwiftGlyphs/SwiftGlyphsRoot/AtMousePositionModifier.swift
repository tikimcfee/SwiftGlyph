//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/17/24.
//

import SwiftUI
import MetalLink

struct AtMousePositionModifier: ViewModifier {
    public let link: MetalLink
    public let cursorOffset: CGFloat = 24.0
    
    var proxy: GeometryProxy
    @State var mousePosition: LFloat2?
    
    func body(content: Content) -> some View {
        #if os(macOS)
        content.onReceive(link.input.sharedMouse) { event in
            mousePosition = event.locationInWindow.asSimd
        }.offset(
            mousePosition.map {
                CGSize(
                    width: $0.x.cg + cursorOffset,
                    height: proxy.size.height - $0.y.cg - cursorOffset
                )
            } ?? CGSizeZero
        )
        #endif
    }
}

extension View {
    func attachedToMousePosition(
        in parentProxy: GeometryProxy,
        with link: MetalLink
    ) -> some View {
        modifier(AtMousePositionModifier(
            link: link,
            proxy: parentProxy
        ))
    }
}

