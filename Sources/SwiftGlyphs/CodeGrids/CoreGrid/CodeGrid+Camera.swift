//
//  CodeGrid+Camera.swift
//  SwiftGlyph
//
//  Created by Ivan Lugo on 11/13/24.
//


import Foundation
import MetalLink
import MetalLinkHeaders

public extension CodeGrid {
    func displayFocused(_ camera: DebugCamera) {
        guard parent != nil else {
            print("Trying to lock on unparented node. Wuh?")
            return
        }
        
        var bounds = worldBounds
//        bounds.min.x -= 4
//        bounds.max.x += 4
//        bounds.min.y -= 8
//        bounds.max.y += 16
        bounds.min.z -= 8
        bounds.max.z += 196
        
//        let position = bounds.center
        camera.interceptor.resetPositions()
        camera.position = LFloat3(
            bounds.leading + 20,
            bounds.top,
            bounds.front
        )
        camera.rotation = .zero
        camera.scrollBounds = bounds
    }
}
