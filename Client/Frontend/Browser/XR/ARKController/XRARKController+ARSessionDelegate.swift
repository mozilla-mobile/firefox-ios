import ARKit

@available(iOS 12.0, *)
extension ARKController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if let controller = controller as? ARKMetalController {
            controller.renderer.interfaceOrientation = UIApplication.shared.statusBarOrientation
            
            if controller.previewingSinglePlane,
                let frame = session.currentFrame
            {
                let boundsSize = controller.getRenderView().bounds.size
                controller.renderer.showDebugPlanes = true
                let transform = frame.displayTransform(for: controller.renderer.interfaceOrientation, viewportSize: boundsSize)
                let frameUnitPoint = CGPoint(x: 0.5, y: 0.5).applying(transform.inverted())
                
                if let firstHitTestResult = frame.hitTest(frameUnitPoint, types: .existingPlaneUsingGeometry).first,
                    let anchor = firstHitTestResult.anchor,
                    let node = controller.planes[anchor.identifier]
                {
                    controller.focusedPlane = node
                    node.geometry?.elements.first?.material.diffuse.contents = UIColor.green
                }
            } else if controller.showMode != .debug && controller.showMode != .urlDebug {
                controller.renderer.showDebugPlanes = false
            }
        }
        if shouldUpdateWindowSize {
            self.shouldUpdateWindowSize = false
            didUpdateWindowSize?()
        }
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("Add Anchors - \(anchors.debugDescription)")
        
        if webXRAuthorizationStatus == .notDetermined {
            for anchor in anchors {
                session.remove(anchor: anchor)
            }
            return
        }
        
        for addedAnchor: ARAnchor in anchors {
            if addedAnchor is ARFaceAnchor && !(configuration is ARFaceTrackingConfiguration) {
                print("Trying to add a face anchor to a session configuration that's not ARFaceTrackingConfiguration")
                continue
            }

            if let controller = controller as? ARKMetalController,
                addedAnchor is ARPlaneAnchor
            {
                let node = Node()
                controller.planes[addedAnchor.identifier] = node
                node.transform = Transform(from: addedAnchor.transform)
                controller.renderer.scene?.rootNode.addChildNode(node)
                controller.renderer(didAddNode: node, forAnchor: addedAnchor)
            }
            
            if shouldSend(addedAnchor)
                || webXRAuthorizationStatus == .worldSensing
                || webXRAuthorizationStatus == .videoCameraAccess
            // Tony: Initially I implemented a line below to allow face-based and image-based AR
            // experiences to work when operating in .singlePlane/AR Lite Mode.  However
            // if the user is choosing to operate in AR Lite Mode (i.e. a mode focused on
            // restricting the amount of data shared), they likely wouldn't want the website to
            // utilize any recognized ARFaceAnchors nor, potentially, ARImageAnchors.
            // Tony: Spoke with Blair briefly about this 2/4/19, allowing ARFaceAnchors
            //       but not ARImageAnchors
                || (webXRAuthorizationStatus == .lite && addedAnchor is ARFaceAnchor)
            {
                
                let addedAnchorDictionary = createDictionary(for: addedAnchor)
                addedAnchorsSinceLastFrame.add(addedAnchorDictionary)
                objects[anchorID(for: addedAnchor)] = addedAnchorDictionary
            }
            
            if let addedAnchor = addedAnchor as? ARImageAnchor {
                if webXRAuthorizationStatus == .worldSensing || webXRAuthorizationStatus == .videoCameraAccess {
                    guard let name = addedAnchor.referenceImage.name else { return }
                    let addedAnchorDictionary = createDictionary(for: addedAnchor)
                    if detectionImageActivationPromises[name] != nil {
                        let promise = detectionImageActivationPromises[name] as? ActivateDetectionImageCompletionBlock
                        // Call the detection image block
                        promise?(true, nil, addedAnchorDictionary as? [AnyHashable: Any])
                        detectionImageActivationPromises[name] = nil
                    }
                } else if webXRAuthorizationStatus == .minimal || webXRAuthorizationStatus == .lite {
                    session.remove(anchor: addedAnchor)
                }
            }
        }
    }
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for updatedAnchor: ARAnchor in anchors {
            if updatedAnchor is ARFaceAnchor && !(configuration is ARFaceTrackingConfiguration) {
                print("Trying to update a face anchor in a session configuration that's not ARFaceTrackingConfiguration")
                continue
            }
            
            if let controller = controller as? ARKMetalController,
                updatedAnchor is ARPlaneAnchor,
                let node = controller.planes[updatedAnchor.identifier]
            {
                node.transform = Transform(from: updatedAnchor.transform)
                controller.renderer(didUpdateNode: node, forAnchor: updatedAnchor)
            }
            
            if let anchorDictionary = objects[anchorID(for: updatedAnchor)] as? NSDictionary,
                !addedAnchorsSinceLastFrame.contains(anchorDictionary)
            {
                updateDictionary(for: updatedAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print("Remove Anchors - \(anchors.debugDescription)")
        for removedAnchor: ARAnchor in anchors {
            
            if let controller = controller as? ARKMetalController,
                removedAnchor is ARPlaneAnchor,
                let node = controller.planes[removedAnchor.identifier]
            {
                node.removeFromParentNode()
                controller.planes[removedAnchor.identifier] = nil
            }
            
            let anchorID = self.anchorID(for: removedAnchor)
            if objects[anchorID] != nil {
                removedAnchorsSinceLastFrame.add(anchorID)
                objects[anchorID] = nil
                
                arkitGeneratedAnchorIDUserAnchorIDMap[removedAnchor.identifier.uuidString] = nil
                if let imageAnchor = removedAnchor as? ARImageAnchor,
                    let completion = detectionImageActivationAfterRemovalPromises[imageAnchor.referenceImage.name ?? ""] as? ActivateDetectionImageCompletionBlock
                {
                    activateDetectionImage(imageAnchor.referenceImage.name, completion: completion)
                    detectionImageActivationAfterRemovalPromises[imageAnchor.referenceImage.name ?? ""] = nil
                }
            } else {
                if arkitGeneratedAnchorIDUserAnchorIDMap[removedAnchor.identifier.uuidString] != nil {
                    print("Remove Anchor not in objects, but in UserAnchorIDMap - \(anchorID)")
                }
            }
        }
    }
}
