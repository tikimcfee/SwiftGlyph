//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/14/24.
//

import Foundation
import CoreGraphics

public struct ComponentState: Codable, Equatable {
    public var origin: CGPoint
    public var size: CGSize

    public init(
        origin: CGPoint = .zero,
        size: CGSize = .init(width: 300, height: 300)
    ) {
        self.origin = origin
        self.size = size
    }
}

public struct ComponentModel: Codable, Equatable {
    public var componentInfo = ComponentState()
    public var dragOffset: CGSize? = nil
    public var resizeOffset: CGSize? = nil
    public var resizePoint: ResizePoint? = nil

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
    
    mutating func updateForResize(
        using resizePoint: ResizePoint,
        deltaX: CGFloat,
        deltaY: CGFloat
    ) {
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

    mutating func dragEnded() {
        guard let dragOffset else { return }
        componentInfo.origin.x += dragOffset.width
        componentInfo.origin.y += dragOffset.height
        self.dragOffset = nil
    }
}
