//  
//
//  Created on 12/29/23.
//  

import MetalLink

class TouchState {
    var pan = TouchStart()
}

class TouchStart {
    private var cam: DebugCamera {
        GlobalInstances.debugCamera
    }
    
    var positioningNode = MetalLinkNode()
    var positioningNodeStart = LFloat3.zero
    var valid: Bool = false
   
    var initialCameraPosition = LFloat3.zero
    var initialObjectPosition = LFloat3.zero
    var initialDistance = Float.zero
    
    var lastScreenCoordinate = LFloat2.zero
   
    var projectionDepthPosition = LFloat3.zero
    var computedStartUnprojection = LFloat3.zero

    func setStartUnprojection(
        screenPosition: LFloat2
    ) {
        computedStartUnprojection = cam.unprojectPoint(
            screenPosition,
            worldDepth: projectionDepthPosition.z
        )
    }
    
    func computedEndUnprojection(with location: LFloat2) -> LFloat3 {
        cam.unprojectPoint(
            location,
            worldDepth: projectionDepthPosition.z // Use the same depth as the start
        )
    }
}
