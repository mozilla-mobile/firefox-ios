import ARKit

@available(iOS 12.0, *)
extension ARKController: ARSessionObserver {
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        didChangeTrackingState?(camera)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("sessionWasInterrupted")
        sessionWasInterrupted?()
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("sessionInterruptionEnded")
        sessionInterruptionEnded?()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session didFailWithError - \(error.localizedDescription)")
        didFailSession?(error)
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
}
