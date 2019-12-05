import ARKit

@available(iOS 12.0, *)
extension ARKController {
    /**
     Updates the internal AR Request dictionary
     Creates an ARKit configuration object
     Runs the ARKit session
     Updates the session state to running
     Updates the show mode and the show options
     
     @param state The current app state
     */
    func startSession(with state: AppState) {
        updateARConfiguration(with: state)
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arSessionState = .arkSessionRunning
        
        // if we are removing anchors, clear the user map
        arkitGeneratedAnchorIDUserAnchorIDMap = NSMutableDictionary()
        
        // if we've already received authorization for CV or WorldState data, likely because of a preference setting or
        // previous saved approval for the site, make sure we set up the state properly here
        if state.askedComputerVisionData {
            computerVisionDataEnabled = state.userGrantedSendingComputerVisionData
        }
        if state.askedWorldStateData {
            webXRAuthorizationStatus = state.userGrantedSendingWorldStateData
        }
        
        setupDeviceCamera()
        setShowMode(state.showMode)
        setShowOptions(state.showOptions)
        UserDefaults.standard.set(Date(), forKey: Constant.lastResetSessionTrackingDateKey())
    }
    
    /**
     Updates the internal AR request dictionary.
     Creates a AR configuration object based on the request.
     Runs the session.
     Sets the session status to running.
     
     @param state the app state
     */
    func runSession(with state: AppState) {
        updateARConfiguration(with: state)
        session.run(configuration, options: [])
        arSessionState = .arkSessionRunning
    }
    
    func runSessionRemovingAnchors(with state: AppState) {
        updateARConfiguration(with: state)
        session.run(configuration, options: .removeExistingAnchors)
        // If we are removing anchors, clear the user map
        arkitGeneratedAnchorIDUserAnchorIDMap = NSMutableDictionary()
        arSessionState = .arkSessionRunning
    }
    
    func runSessionResettingTrackingAndRemovingAnchors(with state: AppState) {
        updateARConfiguration(with: state)
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        // If we are removing anchors, clear the user map
        arkitGeneratedAnchorIDUserAnchorIDMap = NSMutableDictionary()
        arSessionState = .arkSessionRunning
        UserDefaults.standard.set(Date(), forKey: Constant.lastResetSessionTrackingDateKey())
    }
    
    /**
     Updates the internal AR Request dictionary and the configuration
     Runs the session
     Updates the session state to running
     Updates the show mode and the show options
     
     @param state The current app state
     */
    
    // The session was paused, which implies it was off of the AR page, somewhere 2D, for a bit
    func resumeSession(with state: AppState) {
        request = state.aRRequest
        
        if configuration is ARWorldTrackingConfiguration {
            let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
            if hasBackgroundWorldMap() {
                worldTrackingConfiguration?.initialWorldMap = backgroundWorldMap
                backgroundWorldMap = nil
                print("using Saved WorldMap to resume session")
            } else {
                worldTrackingConfiguration?.initialWorldMap = nil
                print("no Saved WorldMap, resuming without background worldmap")
            }
        } else {
            print("resume session on a face-tracking camera")
        }
        session.run(configuration, options: [])
        arSessionState = .arkSessionRunning
        setupDeviceCamera()
        setShowMode(state.showMode)
        setShowOptions(state.showOptions)
    }
    
    /**
     Updates the internal AR Request dictionary and the configuration
     Runs the session
     Updates the session state to running
     Updates the show mode and the show options
     
     @param state The current app state
     */
    
    // The app was backgrounded, so try to reactivate the session map
    func resumeSession(fromBackground state: AppState) {
        request = state.aRRequest
        
        if configuration is ARWorldTrackingConfiguration {
            let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
            if hasBackgroundWorldMap() {
                worldTrackingConfiguration?.initialWorldMap = backgroundWorldMap
                backgroundWorldMap = nil
                print("using Saved WorldMap to resume session")
            } else {
                worldTrackingConfiguration?.initialWorldMap = nil
                print("no Saved WorldMap, resuming without background worldmap")
            }
        } else {
            print("resume session on a face-tracking camera")
        }
        session.run(configuration, options: [])
        arSessionState = .arkSessionRunning
    }
    
    /**
     Pauses the AR session and sets the arSessionState to paused
     */
    func pauseSession() {
        session.pause()
        arSessionState = .arkSessionPaused
    }
    
    func updateARConfiguration(with state: AppState) {
        request = state.aRRequest
        
        // lets make sure we pick a low res video format
        // NOTE:  might want to make this a preference option in the future
        // Make sure there is no initial worldmap set
        if configuration is ARWorldTrackingConfiguration {
            let supportedFormats = ARWorldTrackingConfiguration.supportedVideoFormats
            let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
            if var videoFormat = worldTrackingConfiguration?.videoFormat {
                for format: ARConfiguration.VideoFormat in supportedFormats {
                    if (format.imageResolution.width < videoFormat.imageResolution.width ||
                        format.imageResolution.height < videoFormat.imageResolution.height ) {
                        videoFormat = format
                    }
                }
                worldTrackingConfiguration?.videoFormat = videoFormat
            }
            worldTrackingConfiguration?.initialWorldMap = nil
            if hasBackgroundWorldMap() {
                backgroundWorldMap = nil
                print("clearing Saved Background WorldMap from resume session")
            }
            
            worldTrackingConfiguration?.maximumNumberOfTrackedImages = state.numberOfTrackedImages

        } else if configuration is ARFaceTrackingConfiguration {
            let supportedFormats = ARFaceTrackingConfiguration.supportedVideoFormats
            let faceTrackingConfiguration = configuration as? ARFaceTrackingConfiguration
            if var videoFormat = faceTrackingConfiguration?.videoFormat {
                for format: ARConfiguration.VideoFormat in supportedFormats {
                    if (format.imageResolution.width < videoFormat.imageResolution.width ||
                        format.imageResolution.height < videoFormat.imageResolution.height
                        //|| (format.framesPerSecond >= 30 && format.framesPerSecond < videoFormat.framesPerSecond)
                        ) {
                        videoFormat = format
                    }
                }
                faceTrackingConfiguration?.videoFormat = videoFormat
            }
        }
        
        if state.aRRequest[WEB_AR_WORLD_ALIGNMENT] as? Bool ?? false {
            configuration.worldAlignment = .gravityAndHeading
        } else {
            configuration.worldAlignment = .gravity
        }
    }
    
    // MARK: - Helpers
    
    func currentFrameTimeInMilliseconds() -> TimeInterval {
        return TimeInterval((session.currentFrame?.timestamp ?? 0.0) * 1000)
    }
    
    func trackingStateNormal() -> Bool {
        guard let ts = session.currentFrame?.camera.trackingState.presentationString else {
            print("Unable to check if camera trackingState presentationString is normal")
            return false
        }
        return ts == ARCamera.TrackingState.normal.presentationString
    }
    
    func trackingStateRelocalizing() -> Bool {
        guard let ts = session.currentFrame?.camera.trackingState.presentationString else {
            print("Unable to check if camera trackingState presentationString is relocalizing")
            return false
        }
        return ts == ARCamera.TrackingState.limited(.relocalizing).presentationString
    }
    
    func setShowMode(_ showMode: ShowMode) {
        controller.setShowMode(showMode)
    }
    
    func setShowOptions(_ showOptions: ShowOptions) {
        self.showOptions = showOptions
        controller.setShowOptions(showOptions)
    }
    
    /**
     ARKit data creates a copy of the current AR data and returns it
     
     @return the dictionary that's going to be sent to JS
     */
    func getARKData() -> [AnyHashable : Any] {
        var data: [AnyHashable : Any]
        var localLock = os_unfair_lock()
        localLock = lock
        os_unfair_lock_lock(&(localLock))
        data = arkData
        os_unfair_lock_unlock(&(localLock))
        lock = localLock
        
        return data
//        return arkData
    }
    
    /**
     computer vision data creates a copy of the current CV data and returns it
     
     @return the dictionary of CV data that's going to be sent to JS
     */
    func getComputerVisionData() -> [AnyHashable : Any]? {
        var data: [AnyHashable : Any]
        var localLock = os_unfair_lock()
        localLock = lock
        os_unfair_lock_lock(&(localLock))
        data = computerVisionData
        computerVisionData = [:]
        os_unfair_lock_unlock(&(localLock))
        lock = localLock
        
        return data
    }
    
    /**
     Performs a hit test over the scene
     
     @param point source point for the ray casting in normalized coordinates
     @param type A bit mask representing the hit test types to be considered
     @return an array of hit tests
     */
    func hitTestNormPoint(_ normPoint: CGPoint, types type: Int) -> [[AnyHashable: Any]] {
        var point = CGPoint()
        if usingMetal {
            point = normPoint
        } else {
            let renderSize: CGSize? = controller.getRenderView().bounds.size
            point = CGPoint(x: normPoint.x * (renderSize?.width ?? 0.0), y: normPoint.y * (renderSize?.height ?? 0.0))
        }
        let result = controller.hitTest(point, with: ARHitTestResult.ResultType(rawValue: UInt(type)))
        return hitTestResultArrayFromResult(resultArray: result)
    }
    
    private func hitTestResultArrayFromResult(resultArray: [ARHitTestResult]) -> [[AnyHashable: Any]] {
        var results = [[AnyHashable: Any]]()
        
        for result: ARHitTestResult in resultArray {
            var dict = [AnyHashable : Any]()
            
            dict[WEB_AR_TYPE_OPTION] = NSNumber(value: result.type.rawValue)
            dict[WEB_AR_W_TRANSFORM_OPTION] = result.worldTransform.array()
            dict[WEB_AR_L_TRANSFORM_OPTION] = result.localTransform.array()
            dict[WEB_AR_DISTANCE_OPTION] = result.distance
            dict[WEB_AR_UUID_OPTION] = result.anchor?.identifier.uuidString ?? ""
            
            if let planeAnchor = result.anchor as? ARPlaneAnchor {
                dict[WEB_AR_ANCHOR_CENTER_OPTION] = dictFromVector3(planeAnchor.center)
                dict[WEB_AR_ANCHOR_EXTENT_OPTION] = dictFromVector3(planeAnchor.extent)
                dict[WEB_AR_ANCHOR_TRANSFORM_OPTION] = planeAnchor.transform.array()
            }
            
            results.append(dict)
        }
        
        return results
    }
}
