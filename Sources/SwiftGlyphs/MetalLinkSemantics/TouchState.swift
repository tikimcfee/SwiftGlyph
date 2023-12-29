//  
//
//  Created on 12/29/23.
//  

import MetalLink

class TouchState {
    var pan = TouchStart()
}

class TouchStart {
    var valid: Bool = false
    var gesturePoint = LFloat2.zero
    var initialCameraPosition = LFloat3.zero
    var initialObjectPosition = LFloat3.zero
    var initialDistance = Float.zero
    var initialIntersectionPoint: LFloat3 = .zero
    var isFirstMovement: Bool = true
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
