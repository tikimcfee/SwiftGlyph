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
        touchState.pan.gesturePoint = event.currentLocation
        touchState.pan.projectionDepthPosition = camera.projectPoint(grid.rootNode.position)
        touchState.pan.computeStartUnprojection()
        touchState.pan.initialCameraPosition = camera.position
        touchState.pan.initialObjectPosition = grid.rootNode.worldPosition
        touchState.pan.initialDistance = camera.position.distance(to: grid.rootNode.worldPosition)
        touchState.pan.valid = true
        
        // Calculate the initial intersection point based on the object's current world position
        let initialRay = camera.castRay(from: event.currentLocation)
        touchState.pan.initialIntersectionPoint = intersectRayWithSphere(
            rayOrigin: initialRay.origin,
            rayDirection: initialRay.direction,
            sphereCenter: camera.position,
            sphereRadius: touchState.pan.initialDistance
        )
    }
    
    func panOnNode(_ event: PanEvent) {
        let currentLocation = event.currentLocation
        
        // Cast a ray from the camera through the current mouse position
        let currentRay = camera.castRay(from: currentLocation)
        
        // Find the intersection of this ray with the sphere
        let currentIntersection = intersectRayWithSphere(
            rayOrigin: currentRay.origin,
            rayDirection: currentRay.direction,
            sphereCenter: camera.position,
            sphereRadius: touchState.pan.initialDistance
        )
        
        // Calculate the offset from the initial intersection point
        let offsetFromInitialIntersection = currentIntersection - touchState.pan.initialIntersectionPoint
        
        // Apply this offset to the object's initial world position to get the new position
        let newWorldPosition = touchState.pan.initialObjectPosition + offsetFromInitialIntersection
        
        // Move the object to this new world position
        touchState.pan.positioningNode.setWorldPosition(newWorldPosition)
        
        // If this is the first movement, update the initial intersection point
        if touchState.pan.isFirstMovement {
            touchState.pan.initialIntersectionPoint = currentIntersection
            touchState.pan.isFirstMovement = false
        }
    }
}

private extension PanController {
    func panOnNodeXY(_ event: PanEvent) {
        
    }
}

private extension PanController {
    func panOnNode3(_ event: PanEvent) {
        let currentLocation = event.currentLocation
        
        // Cast a ray from the camera through the current mouse position
        let currentRay = camera.castRay(from: currentLocation)
        
        // Find the intersection of this ray with the sphere
        let currentIntersection = intersectRayWithSphere(
            rayOrigin: currentRay.origin,
            rayDirection: currentRay.direction,
            sphereCenter: camera.position,
            sphereRadius: touchState.pan.initialDistance
        )
        
        // Calculate the offset from the initial intersection point
        let offsetFromInitialIntersection = currentIntersection - touchState.pan.initialIntersectionPoint
        
        // Apply this offset to the object's initial world position to get the new position
        var newWorldPosition = touchState.pan.initialObjectPosition + offsetFromInitialIntersection
        
        // Since we want to maintain the initial distance from the camera, we project the new position onto the sphere
        let directionFromCamera = (newWorldPosition - camera.position).normalized
        newWorldPosition = camera.position + directionFromCamera * touchState.pan.initialDistance
        
        // Move the object to this new world position
        touchState.pan.positioningNode.setWorldPosition(newWorldPosition)
    }
}

private extension PanController {
    func transformScreenDeltaToWorld(_ screenDelta: LFloat2) -> LFloat3 {
        // Transform the screen space delta into world space using the camera's matrices
        let viewProjectionInverse = (camera.projectionMatrix * camera.viewMatrix).inverse
        let worldDelta4 = viewProjectionInverse * LFloat4(screenDelta.x, screenDelta.y, 0, 0)
        return LFloat3(worldDelta4.x, worldDelta4.y, worldDelta4.z)
    }
    
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
