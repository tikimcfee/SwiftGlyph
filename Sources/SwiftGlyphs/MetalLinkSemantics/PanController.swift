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

    private func panBegan(
        _ event: PanEvent,
        on grid: CodeGrid
    ) {
        touchState.pan.positioningNode = grid.rootNode
        touchState.pan.gesturePoint = event.currentLocation
        let depthPosition = camera.projectPoint(touchState.pan.positioningNode.position)
        touchState.pan.projectionDepthPosition = depthPosition // Store the depth
        touchState.pan.computeStartUnprojection()
        touchState.pan.valid = true
    }

    private func panOnNode(_ event: PanEvent) {
        // Compute the unprojection for the current point
        let currentLocation = event.currentLocation
        let endUnprojection = touchState.pan.computedEndUnprojection(with: currentLocation)
        
        // Calculate the delta in world space
        let delta = endUnprojection - touchState.pan.computedStartUnprojection
        
        // Apply the delta to the node's position
        print(delta)
        touchState.pan.positioningNode.position += delta
        
        // Update the start unprojection to the current unprojection for the next frame
        touchState.pan.computedStartUnprojection = endUnprojection
    }
}

class TouchState {
    var pan = TouchStart()
}

class TouchStart {
    var valid: Bool = false
    var gesturePoint = LFloat2.zero

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
