import Foundation
import SwiftUI
import MetalLink
import MetalLinkHeaders
import simd

// Adapted from https://stackoverflow.com/questions/48970111/rotating-scnnode-on-y-axis-based-on-pan-gesture
public class PanController {
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

        if panEvent.pressingCommand, let start = panEvent.commandStart {
            // Can always rotate the camera
            panHoldingCommand(panEvent, start)
        } else if touchState.pan.valid {
            if panEvent.pressingOption, let start = panEvent.optionStart {
                panHoldingOption(panEvent, start)
            } else {
                panOnNode(panEvent)
            }
        }

        if panEvent.state == .ended {
            touchState.pan = TouchStart()
            touchState.pan.valid = false
            print("-- Ended pan")
        }
    }
}

public extension PanController {
    private func panBegan(_ event: PanEvent, on grid: CodeGrid) {
        touchState.pan.lastScreenCoordinate = event.currentLocation
        touchState.pan.positioningNode = grid.rootNode
        touchState.pan.positioningNodeStart = grid.rootNode.position
        
        touchState.pan.cameraRotation = camera.rotation
        touchState.pan.nodeRotation = grid.rootNode.rotation
        
        touchState.pan.projectionDepthPosition = grid.rootNode.position
        touchState.pan.setStartUnprojection(mouse: event.currentLocation)
        
        touchState.pan.valid = true
        print("-- Found a node; touch valid")
    }

    private func panOnNode(_ event: PanEvent) {
        // Previous world space touch position
        let previousWorldPosition = touchState.pan.computedStartUnprojection
        
        // Current world space touch position
        let currentWorldPosition = touchState.pan.cameraUnprojection(mouse: event.currentLocation)

        // World space delta between touch positions
        let worldDelta = currentWorldPosition - previousWorldPosition

        // Node's initial world space position
        var nodeWorldPosition = touchState.pan.positioningNodeStart

        // Apply world space delta to node's position
        nodeWorldPosition += worldDelta

        // Update node's world space position
        touchState.pan.positioningNode.position = nodeWorldPosition

        // Update previous touch location
        touchState.pan.lastScreenCoordinate = event.currentLocation
    }

    private func panHoldingOption(_ event: PanEvent, _ start: LFloat2) {
        let end = event.currentLocation
        let rotation = rotationBetween(start, end, using: touchState.pan.nodeRotation)
        guard rotation.x != 0.0 || rotation.y != 0 else { return }
        
        touchState.pan.positioningNode.rotation.y = rotation.y.vector
        touchState.pan.positioningNode.rotation.x = rotation.x.vector
        
        // Reset position 'start' position after rotation
        touchState.pan.lastScreenCoordinate = event.currentLocation
        touchState.pan.positioningNodeStart = touchState.pan.positioningNode.position
        touchState.pan.projectionDepthPosition = camera.projectPoint(touchState.pan.positioningNode.position)
        touchState.pan.setStartUnprojection(mouse: end)
    }
    
    private func panHoldingCommand(_ event: PanEvent, _ start: LFloat2) {
        let scaledStart = start * 0.33
        let end = event.currentLocation * 0.33
        if scaledStart == end {
            touchState.pan.cameraRotation = camera.rotation
            return
        }

        // reverse start and end to reverse camera control style
        let rotation = rotationBetween(
            end,
            scaledStart,
            using: touchState.pan.cameraRotation
        )
        guard rotation.x != 0.0 || rotation.y != 0 
        else { return }

        camera.rotation.y = rotation.y.vector
        camera.rotation.x = rotation.x.vector
    }

    private func rotationBetween(_ startPosition: LFloat2,
                                 _ endPosition: LFloat2,
                                 using currentAngles: LFloat3) -> LFloat2 {
        let translation = LFloat2(x: endPosition.x - startPosition.x,
                                  y: endPosition.y - startPosition.y)
        guard translation.x != 0.0 || translation.y != 0.0 
        else { return .zero }
        
        var newAngleY = translation.x * Float.pi/180.0
        var newAngleX = -translation.y * Float.pi/180.0
        newAngleY += currentAngles.y
        newAngleX += currentAngles.x
        return LFloat2(x: newAngleX, y: newAngleY)
    }
}
