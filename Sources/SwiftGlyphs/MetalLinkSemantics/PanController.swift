import Foundation
import SwiftUI
import MetalLink
import MetalLinkHeaders

// Adapted from https://stackoverflow.com/questions/48970111/rotating-scnnode-on-y-axis-based-on-pan-gesture
class PanController {
    var touchState: TouchState = TouchState()
    var camera: DebugCamera { GlobalInstances.debugCamera }
    
    func pan(
        _ panEvent: PanEvent,
        on grid: CodeGrid
    ) {
        if panEvent.state == .began {
            print("-- Starting pan on \(grid.fileName)")
            panBegan(panEvent, on: grid)
        }
        
        if touchState.pan.valid {
            panOnNode(panEvent)
        }
        
        if panEvent.state == .ended {
            touchState.pan = TouchStart()
            touchState.pan.valid = false
            print("-- Ended pan on \(grid.fileName)")
        }
    }
}

private extension PanController {
    func panBegan(
        _ event: PanEvent,
        on grid: CodeGrid
    ) {
        touchState.pan.positioningNode = grid.rootNode
        touchState.pan.lastScreenCoordinate = event.currentLocation
        touchState.pan.initialCameraPosition = camera.position
        touchState.pan.initialObjectPosition = grid.rootNode.worldPosition
        touchState.pan.initialDistance = camera.position.distance(to: grid.rootNode.worldPosition)
        touchState.pan.projectionDepthPosition = grid.rootNode.worldPosition
        touchState.pan.setStartUnprojection(screenPosition: event.currentLocation)
        touchState.pan.valid = true
    }
    
    func panOnNode(_ event: PanEvent) {
        // Calculate the screen space delta
        let current = event.currentLocation
        let previous = touchState.pan.lastScreenCoordinate
        
        let startProjection = touchState.pan.computedStartUnprojection
        let endProjection = touchState.pan.computedEndUnprojection(with: previous)
        let transform = endProjection - startProjection
        
        
        let initial = touchState.pan.initialObjectPosition
        let initialProject = camera.projectPoint(initial)
        let appliedTransform = initialProject + transform
        print("""
        startProjection: \(startProjection.tupleString)
        endProjection:   \(endProjection.tupleString)
        current:         \(current.tupleString)
        previous:        \(previous.tupleString)
        transform:       \(transform.tupleString)
        applied:         \(appliedTransform.tupleString)
        --------------------------------------------------
        """)
    }
}

private extension PanController {
    
    func intersectRayWithSphere(rayOrigin: LFloat3, rayDirection: LFloat3, sphereCenter: LFloat3, sphereRadius: Float) -> LFloat3 {
        // Calculate the vector from the ray origin to the sphere center
        let originToCenter = sphereCenter - rayOrigin
        // Project this vector onto the ray direction
        let projectionLength = simd_dot(originToCenter, rayDirection)
        // Calculate the closest point on the ray to the sphere center
        let closestPoint = rayOrigin + rayDirection * projectionLength
        // Calculate the distance from the closest point to the sphere center
        let centerToClosestPointLength = simd_length(sphereCenter - closestPoint)
        // Calculate the intersection point using Pythagorean theorem
        let offsetLength = sqrt(sphereRadius * sphereRadius - centerToClosestPointLength * centerToClosestPointLength)
        // The intersection point is along the ray direction, offset from the closest point
        let intersectionPoint = closestPoint + rayDirection * offsetLength
        return intersectionPoint
    }
}
