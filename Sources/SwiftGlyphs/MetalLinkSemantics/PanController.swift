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
            panOnNode3(panEvent)
        }

        if panEvent.state == .ended {
            touchState.pan = TouchStart()
            touchState.pan.valid = false
            print("-- Ended pan on \(grid.fileName)")
        }
    }

    private func panBegan(
        _ event: PanEvent,
        on grid: CodeGrid
    ) {
        touchState.pan.positioningNode = grid.rootNode
        touchState.pan.gesturePoint = event.currentLocation
        touchState.pan.projectionDepthPosition = camera.projectPoint(grid.rootNode.position)
        touchState.pan.computeStartUnprojection()
        touchState.pan.initialCameraPosition = camera.position
        touchState.pan.initialObjectPosition = grid.rootNode.worldPosition
        touchState.pan.valid = true
    }

    private func panOnNode1(
        _ event: PanEvent
    ) {
        let currentLocation = event.currentLocation
        let startUnprojection = touchState.pan.computedStartUnprojection
        let endUnprojection = touchState.pan.computedEndUnprojection(with: currentLocation)
        
        // Calculate the translation vector in world space
        var translation = endUnprojection - startUnprojection
        
        // Adjust the translation based on the camera's orientation
        let cameraOrientation = camera.rotation.xyzQuaternian()
        translation = simd_act(cameraOrientation.inverse, translation)
        
        // If the camera moved forward/backward, adjust the object's position to maintain relative distance
        if camera.position.z != touchState.pan.initialCameraPosition.z {
            let cameraMovementZ = camera.position.z - touchState.pan.initialCameraPosition.z
            translation.z -= cameraMovementZ
        }
        
        // Apply the translation to the object's position
        touchState.pan.positioningNode.position += translation
        
        // Update the initial camera position if the camera moved
        if event.state == .changed {
            touchState.pan.initialCameraPosition = camera.position
        }
        
        // Update the start unprojection for the next frame
        touchState.pan.computedStartUnprojection = endUnprojection
    }
    
    private func panOnNode2(
        _ event: PanEvent
    ) {
        let currentLocation = event.currentLocation
        let previousLocation = touchState.pan.gesturePoint
        
        // Calculate the mouse movement delta in screen space
        let screenDelta = currentLocation - previousLocation
        
        // Convert the screen delta to a world space direction
        let worldDelta = screenToWorldDelta(screenDelta, atDepth: touchState.pan.projectionDepthPosition.z)
        
        // Move the object by the world space delta
        touchState.pan.positioningNode.position += worldDelta
        
        // Update the gesture point for the next frame
        touchState.pan.gesturePoint = currentLocation
    }
    
    private func panOnNode3(
        _ event: PanEvent
    ) {
        let currentLocation = event.currentLocation
        let previousLocation = touchState.pan.gesturePoint
        
        // Cast rays for the current and previous mouse positions
        let currentRay = camera.castRay(from: currentLocation)
        let previousRay = camera.castRay(from: previousLocation)
        
        // Find the points on the rays that are a fixed distance from the camera
        let currentPoint = currentRay.origin + currentRay.direction * 100
        let previousPoint = previousRay.origin + previousRay.direction * 100
        
        // Calculate the world space translation
        let translation = currentPoint - previousPoint
        
        // Apply the translation to the object's position
        touchState.pan.positioningNode.position += translation
        
        // Update the gesture point for the next frame
        touchState.pan.gesturePoint = currentLocation
    }
    
    private func calculateDepthAdjustmentFactor() -> Float {
        // Calculate the distance from the camera to the object's position
        let objectPosition = touchState.pan.positioningNode.position
        let cameraToObjectDistance = camera.position.distance(to: objectPosition)
        
        // Use the distance to create a scaling factor for the translation deltas
        // This factor might need to be tuned to get the desired effect
        let depthAdjustmentFactor = cameraToObjectDistance / camera.nearClipPlane
        
        return depthAdjustmentFactor
    }
    
    private func screenToWorldDelta(
        _ screenDelta: LFloat2,
        atDepth depth: Float
    ) -> LFloat3 {
        // Unproject the screen delta at the near plane and far plane to form a ray
        let nearPoint = camera.unprojectPoint(LFloat2(screenDelta.x, screenDelta.y), depth: 0)
        let farPoint = camera.unprojectPoint(LFloat2(screenDelta.x, screenDelta.y), depth: 1)
        
        // Calculate the direction of the ray
        let rayDirection = (farPoint - nearPoint).normalized
        
        // Scale the ray direction by the depth to get the world space delta
        let worldDelta = rayDirection * depth
        
        return worldDelta
    }
}

class TouchState {
    var pan = TouchStart()
}

class TouchStart {
    var valid: Bool = false
    var gesturePoint = LFloat2.zero
    var initialCameraPosition = LFloat3.zero
    var initialObjectPosition = LFloat3.zero
    
    var positioningNode = MetalLinkNode()
    var positioningNodeStart = LFloat3.zero

    var projectionDepthPosition = LFloat3.zero
    var computedStartUnprojection = LFloat3.zero

    var cameraNodeEulers = LFloat3.zero

    func computeStartUnprojection() {
        computedStartUnprojection = GlobalInstances.debugCamera.unprojectPoint(
            gesturePoint,
            depth: projectionDepthPosition.z // Use the stored depth
        )
    }

    func computedEndUnprojection(with location: LFloat2) -> LFloat3 {
        return GlobalInstances.debugCamera.unprojectPoint(
            location,
            depth: projectionDepthPosition.z // Use the same depth as the start
        )
    }
}
