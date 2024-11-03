//  
//
//  Created on 12/29/23.
//  

import MetalLink

class TouchState {
    var pan = TouchStart()
}

class TouchStart {
    private var camera: DebugCamera { GlobalInstances.debugCamera }
    
    // ---------------------------------------
    var positioningNode = MetalLinkNode()
    var positioningNodeStart = LFloat3.zero
    
    var initialCameraPosition = LFloat3.zero
    var initialObjectPosition = LFloat3.zero
    var initialDistance = Float.zero
    
    var lastScreenCoordinate = LFloat2.zero
   
    var projectionDepthPosition = LFloat3.zero
    var computedStartUnprojection = LFloat3.zero
    
    var cameraRotation = LFloat3.zero
    var nodeRotation = LFloat3.zero
    
    var valid: Bool = false
    // ---------------------------------------

    func setStartUnprojection(
        mouse mouseLocation: LFloat2
    ) {
        computedStartUnprojection = camera.unprojectPoint(
            mouseLocation,
            worldDepth: projectionDepthPosition.z
        )
    }
    
    func cameraUnprojection(
        mouse mouseLocation: LFloat2
    ) -> LFloat3 {
        camera.unprojectPoint(
            mouseLocation,
            worldDepth: projectionDepthPosition.z // Use the same depth as the start
        )
    }
}
