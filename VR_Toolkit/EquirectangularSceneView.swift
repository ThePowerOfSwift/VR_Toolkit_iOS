//
//  EquirectangularSceneView.swift
//  director360
//
//  Created by Alexander on 4/20/17.
//  Copyright © 2017 Stanley Chiang. All rights reserved.
//

import UIKit
import SceneKit

class EquirectangularSceneView : SCNView {
    
    var sphereNode : SCNNode?
    var cameraNode : SCNNode?
    
    var mainImage : UIImage! {
        didSet {
            let tmpScene = SCNScene()
            
            //Create node, containing a sphere, using the panoramic image as a texture
            let sphereGeometry = SCNSphere(radius: 999.0)
            sphereGeometry.segmentCount = 96
            sphereGeometry.firstMaterial?.isDoubleSided = true
            sphereGeometry.firstMaterial?.diffuse.contents = mainImage
            
            sphereNode = SCNNode(geometry: sphereGeometry)
            if let sphereNode = sphereNode {
                sphereNode.position = SCNVector3Make(0,0,0)
                sphereNode.scale = SCNVector3Make(-1, 1, 1)
                tmpScene.rootNode.addChildNode(sphereNode)
                
            }
            
            // Camera, ...
            cameraNode = SCNNode()
            if let cameraNode = cameraNode {
                cameraNode.camera = SCNCamera()
                cameraNode.camera?.zFar = 999;
                cameraNode.position = SCNVector3Make(0, 0, 0)
                tmpScene.rootNode.addChildNode(cameraNode)
            }
            
            self.scene = tmpScene;
        }
    }
    
    func horizontalOffsetPixelsToRadians(x : Float) -> (Float) {
        let xFov = GLKMathDegreesToRadians(60)
        return (xFov / Float(self.bounds.size.width)) * x
    }
    
    func verticalOffsetPixelsToRadians(y : Float) -> (Float) {
        let yFov = GLKMathDegreesToRadians(60)
        return (yFov / Float(self.bounds.size.height)) * y
    }
    
    var cameraPosition : GLKQuaternion {
        get {
            return self.cameraNode!.orientation.toGLKQuaternion()
        }
        set(newPosition) {
            self.cameraNode?.orientation = newPosition.toSCNQuaternion()
        }
    }
    
    var originalCameraPosition : GLKQuaternion?
    
    var panStartPoint : CGPoint?
    
    func handlePanGesture(gestureRecognizer : UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .possible:
            break
            
        case .began:
            panStartPoint = gestureRecognizer.translation(in: self)
            beginPanMovement()
            
        case .changed:
            let currentPoint = gestureRecognizer.translation(in: self)
            updatePanMovementOffset(x: Float(currentPoint.x - panStartPoint!.x), y: Float(currentPoint.y - panStartPoint!.y))
            
        default:
            endPanMovement()
        }
    }
    
    func beginPanMovement() {
        originalCameraPosition = cameraNode?.orientation.toGLKQuaternion();
    }
    
    func updatePanMovementOffset(x: Float, y: Float) {
        let xRadians = horizontalOffsetPixelsToRadians(x: x)
        let yRadians = verticalOffsetPixelsToRadians(y: y)
        
        if let originalPosition = originalCameraPosition {
            cameraNode?.orientation = originalPosition.rotateBy(radiansOffsetX: xRadians, radiansOffsetY: yRadians).toSCNQuaternion()
        }
        
    }
    
    func endPanMovement() {
        originalCameraPosition = nil
    }
}

extension GLKQuaternion {
    func rotateBy(radiansOffsetX: Float, radiansOffsetY: Float) -> GLKQuaternion {
        // Perform up and down rotations around *CAMERA* X axis (note the order of multiplication)
        let xMultiplier = GLKQuaternionMakeWithAngleAndAxis(radiansOffsetY, 1, 0, 0)
        var rotatedQuaternion = GLKQuaternionMultiply(self, xMultiplier)
        
        // Perform side to side rotations around *WORLD* Y axis (note the order of multiplication, different from above)
        let yMultiplier = GLKQuaternionMakeWithAngleAndAxis(radiansOffsetX, 0, 1, 0)
        rotatedQuaternion = GLKQuaternionMultiply(yMultiplier, rotatedQuaternion)
        
        return rotatedQuaternion
    }
    
    func rotateBy(radiansOffsetZ: Float) -> GLKQuaternion {
        let zMultiplier = GLKQuaternionMakeWithAngleAndAxis(radiansOffsetZ, 0, 0, 1)
        let rotatedQuaternion = GLKQuaternionMultiply(self, zMultiplier)
        
        return rotatedQuaternion
    }
}
extension GLKQuaternion {
    func toSCNQuaternion() -> SCNQuaternion {
        return SCNQuaternion(self.x, self.y, self.z, self.w)
    }
}

extension SCNQuaternion {
    func toGLKQuaternion() -> GLKQuaternion {
        return GLKQuaternion(q: (self.x, self.y, self.z, self.w))
    }
    
    func toEulerAngles() -> SCNVector3 {
        let roll = atan2(2*(self.y*self.w - self.x*self.z), 1 - 2*self.y*self.y - 2*self.z*self.z).toDegrees()
        let pitch = atan2(2*(self.x*self.w + self.y*self.z), 1 - 2*self.x*self.x - 2*self.z*self.z).toDegrees()
        let yaw = asin(2*self.x*self.y + 2*self.w*self.z).toDegrees()
        
        return SCNVector3(roll, pitch, yaw)
    }
}
extension FloatingPoint {
    func toDegrees() -> Self {
        return self * 180 / .pi
    }
    
    func toRadians() -> Self {
        return self * .pi / 180
    }
}
