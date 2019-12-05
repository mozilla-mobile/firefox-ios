import ARKit

@available(iOS 12.0, *)
extension ARKController {
    
    // MARK: - Camera Device
    
    func setupDeviceCamera() {
        if let videoDevice = AVCaptureDevice.default(for: .video) {
            device = videoDevice
        } else {
            print("Unable to set camera device")
            return
        }
        
        do {
            try device?.lockForConfiguration()
        } catch {
            print("Camera lock error")
            return
        }
        
        if device?.isFocusModeSupported(.continuousAutoFocus) ?? false {
            print("AVCaptureFocusModeContinuousAutoFocus Supported")
            device?.focusMode = .continuousAutoFocus
        }
        
        if device?.isFocusPointOfInterestSupported ?? false {
            print("FocusPointOfInterest Supported")
            device?.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
        }
        
        if device?.isSmoothAutoFocusSupported ?? false {
            print("SmoothAutoFocus Supported")
            device?.isSmoothAutoFocusEnabled = true
        }
        
        device?.unlockForConfiguration()
    }
    
    // MARK: - Camera Button
    
    /**
     Removes all the anchors in the current session.
     
     If the current session is not of class ARFaceTrackingConfiguration, create a
     ARFaceTrackingConfiguration and run the session with it.
     
     Otherwise, create an ARWorldTrackingConfiguration, add the images that were not detected
     in the previous ARWorldTrackingConfiguration session, and run the session.
     */
    func switchCameraButtonTapped(_ state: AppState) { // numberOfTrackedImages: Int) {
        guard let currentFrame = session.currentFrame else { return }
        for anchor in currentFrame.anchors {
            session.remove(anchor: anchor)
        }
        
        if !(configuration is ARFaceTrackingConfiguration) {
            let faceTrackingConfiguration = ARFaceTrackingConfiguration()
            configuration = faceTrackingConfiguration
            runSession(with: state)
        } else {
            let worldTrackingConfiguration = ARWorldTrackingConfiguration()
            worldTrackingConfiguration.planeDetection = [.horizontal, .vertical]
            
            // Configure all the active images that weren't detected in the previous back camera session
            let undetectedImageNames = detectionImageActivationPromises.allKeys
            var newDetectionImages = Set<ARReferenceImage>()
            for imageName: String in undetectedImageNames as? [String] ?? [] {
                if let referenceImage = referenceImageMap[imageName] as? ARReferenceImage {
                    _ = newDetectionImages.insert(referenceImage)
                }
            }
            worldTrackingConfiguration.detectionImages = newDetectionImages
            configuration = worldTrackingConfiguration
            runSession(with: state)
        }
    }
    
    // MARK: - Helpers
    
    class func supportsARFaceTrackingConfiguration() -> Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
}

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "Tracking is unavailable"
        case .normal:
            return ""
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "Limited tracking\nToo much camera movement"
            case .insufficientFeatures:
                return "Limited tracking\nNot enough surface detail"
            case .initializing:
                return "Initializing AR Session"
            case .relocalizing:
                return "Relocalizing\nSlowly scan the space around you"
            }
        }
    }
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement, or reset the session."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface, or reset the session."
        default:
            return nil
        }
    }
}
