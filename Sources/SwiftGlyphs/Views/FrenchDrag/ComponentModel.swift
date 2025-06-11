//
//  File.swift
//  
//
//  Created by Ivan Lugo on 8/14/24.
//

import Foundation
import CoreGraphics

private let minWidth = 100.0
private let minHeight = 100.0

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
        return max(minWidth, componentInfo.size.width + widthOffset)
    }
    
    func heightForCardComponent() -> CGFloat {
        let heightOffset = resizeOffset?.height ?? 0.0
        return max(minHeight, componentInfo.size.height + heightOffset)
    }
    
    func xPositionForCardComponent() -> CGFloat {
        let xPositionOffset = dragOffset?.width ?? 0.0
        let computed = componentInfo.origin.x
            + (componentInfo.size.width / 2.0)
            + xPositionOffset
        return max(0, computed)
    }
    
    func yPositionForCardComponent() -> CGFloat {
        let yPositionOffset = dragOffset?.height ?? 0.0
        let computed = componentInfo.origin.y
            + (componentInfo.size.height / 2.0)
            + yPositionOffset
        return max(0, computed)
    }
    
    mutating func resizeEnded() {
        guard let resizePoint, let resizeOffset else { return }
        
        var width: CGFloat = componentInfo.size.width
        var height: CGFloat = componentInfo.size.height
        var x: CGFloat = componentInfo.origin.x
        var y: CGFloat = componentInfo.origin.y
        switch resizePoint {
        case .topLeft:
            width -= resizeOffset.width
            height -= resizeOffset.height
            x += resizeOffset.width
            y += resizeOffset.height
        case .topMiddle:
            height -= resizeOffset.height
            y += resizeOffset.height
        case .topRight:
            width += resizeOffset.width
            height -= resizeOffset.height
        case .rightMiddle:
            width += resizeOffset.width
        case .bottomRight:
            width += resizeOffset.width
            height += resizeOffset.height
        case .bottomMiddle:
            height += resizeOffset.height
        case .bottomLeft:
            width -= resizeOffset.width
            height += resizeOffset.height
            x -= resizeOffset.width
            y += resizeOffset.height
        case .leftMiddle:
            width -= resizeOffset.width
            x += resizeOffset.width
        }
        self.resizeOffset = nil
        self.resizePoint = nil
        
        let clampedWidth = clamp(width, min: minWidth, max: .infinity)
        let clampedHeight = clamp(height, min: minHeight, max: .infinity)
        componentInfo.size = CGSize(width: clampedWidth, height: clampedHeight)
        componentInfo.origin = CGPoint(x: x, y: y)
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
        
        let clampedWidth = clamp(width, min: minWidth, max: .infinity)
        let clampedHeight = clamp(height, min: minHeight, max: .infinity)
        let clampedX = clamp(x, min: 0, max: .infinity)
        let clampedY = clamp(y, min: 0, max: .infinity)
        
        componentInfo.size = CGSize(width: clampedWidth, height: clampedHeight)
        componentInfo.origin = CGPoint(x: clampedX, y: clampedY)
    }

    mutating func dragEnded() {
        guard let dragOffset else { return }
        let current = componentInfo.origin
        
        let clampedX = clamp(current.x + dragOffset.width, min: 0, max: .infinity)
        let clampedY = clamp(current.y + dragOffset.height, min: 0, max: .infinity)
        
        componentInfo.origin.x = clampedX
        componentInfo.origin.y = clampedY
        
        self.dragOffset = nil
    }
}
