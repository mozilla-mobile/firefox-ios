//
//  Tab+WebXR.swift
//  Client
//
//  Created by Blair MacIntyre on 6/25/20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation

#if WEBXR
import ARKit

extension Tab {
    func setupWebXRWebView() -> TabWebView? {
        //            configuration.mediaTypesRequiringUserActionForPlayback = []
        //            configuration.allowsPictureInPictureMediaPlayback = true
        //            configuration.allowsPictureInPictureMediaPlayback = true
        //            let preferences = WKPreferences()
        //            preferences.javaScriptEnabled = true
        //            configuration.preferences = preferences
                    
        //            browserViewController?.webViewContainer = UIView()
                    
        for view in browserViewController?.webViewContainer.subviews ?? [] {
            view.removeFromSuperview()
        }
        
        setupXRWebController()
        setupXRControllers()
        return webController?.webView
    }
    
    
    func setupXRControllers() {
        setupXRStateController()
//        setupAnimator()
        setupMessageController()
//        setupXRWebController()
//        setupOverlayController()
        setupXRNotifications()
    }
    
    // MARK: - Setup State Controller
    
    func setupXRStateController() {
        weak var blockSelf: Tab? = self

        stateController.onDebug = { showDebug in
            blockSelf?.webController?.showDebug(showDebug)
        }

        stateController.onModeUpdate = { mode in
            blockSelf?.arkController?.setShowMode(mode)
//            blockSelf?.overlayController?.setMode(mode)
            guard let showURL = blockSelf?.stateController.shouldShowURLBar() else { return }
            blockSelf?.webController?.showBar(showURL)
//            if blockSelf?.messageLabel.text != "" {
//                blockSelf?.showHideMessage(hide: !showURL)
//            }
//            blockSelf?.trackingStatusIcon.isHidden = showURL
        }

        stateController.onOptionsUpdate = { options in
            blockSelf?.arkController?.setShowOptions(options)
//            blockSelf?.overlayController?.setOptions(options)
            guard let showURL = blockSelf?.stateController.shouldShowURLBar() else { return }
            blockSelf?.webController?.showBar(showURL)
//            if blockSelf?.messageLabel.text != "" {
//                blockSelf?.showHideMessage(hide: !showURL)
//            }
//            blockSelf?.trackingStatusIcon.isHidden = showURL
        }

        stateController.onXRUpdate = { xr in
//            blockSelf?.messageLabel.text = ""
            if xr {
                guard let debugSelected = blockSelf?.webController?.isDebugButtonSelected() else { return }
                guard let shouldShowSessionStartedPopup = blockSelf?.stateController.state.shouldShowSessionStartedPopup else { return }
                
                if debugSelected {
                    blockSelf?.stateController.setShowMode(.debug)
                } else {
                    blockSelf?.stateController.setShowMode(.nothing)
                }

                var tabsRunningXR = 0
                for tab in blockSelf?.browserViewController?.tabManager.tabs ?? [] {
                    if tab.arkController?.arSessionState == .arkSessionRunning {
                        tabsRunningXR += 1
                    }
                }
                if tabsRunningXR > 1 {
                    blockSelf?.stateController.state.shouldShowSessionStartedPopup = false
                    blockSelf?.messageController?.showMessage(withTitle: MULTIPLE_AR_SESSIONS_TITLE, message: MULTIPLE_AR_SESSIONS_MESSAGE, hideAfter: MULTIPLE_AR_SESSIONS_POPUP_TIME_IN_SECONDS)
                }
                
                if shouldShowSessionStartedPopup {
                    blockSelf?.stateController.state.shouldShowSessionStartedPopup = false
                    blockSelf?.messageController?.showMessage(withTitle: AR_SESSION_STARTED_POPUP_TITLE, message: AR_SESSION_STARTED_POPUP_MESSAGE, hideAfter: AR_SESSION_STARTED_POPUP_TIME_IN_SECONDS)
                }

                blockSelf?.webController?.lastXRVisitedURL = blockSelf?.webController?.webView?.url?.absoluteString ?? ""
                blockSelf?.browserViewController?.scrollController.hideToolbars(animated: true)
                blockSelf?.browserViewController?.urlBar.updateReaderModeState(.unavailable)
            } else {
                blockSelf?.stateController.setShowMode(.nothing)
//                blockSelf?.webController?.barView?.permissionLevelButton?.buttonImage = nil
//                blockSelf?.webController?.barView?.permissionLevelButton?.isEnabled = blockSelf?.arkController?.webXRAuthorizationStatus == .denied ? true : false
                
                blockSelf?.arkController?.pauseSession()
                if blockSelf?.browserViewController?.webViewContainer.subviews.count ?? 1 > 1 {
                    blockSelf?.browserViewController?.webViewContainer.subviews[0].removeFromSuperview()
                }
                blockSelf?.browserViewController?.scrollController.showToolbars(animated: true)
            }
            blockSelf?.updateConstraints()
//            blockSelf?.cancelAllScheduledMessages()
//            blockSelf?.showHideMessage(hide: true)
            blockSelf?.arkController?.controller.initializingRender = true
            blockSelf?.savedRender = nil
//            blockSelf?.trackingStatusIcon.image = nil
            blockSelf?.webController?.setup(forWebXR: xr)
        }

        stateController.onReachable = { url in
            blockSelf?.loadURL(url)
        }

        stateController.onEnterForeground = { url in
            blockSelf?.stateController.state.shouldRemoveAnchorsOnNextARSession = false

            blockSelf?.messageController?.clean()
            let requestedURL = UserDefaults.standard.string(forKey: REQUESTED_URL_KEY)
            if requestedURL != nil {
                print("\n\n*********\n\nMoving to foreground because the user wants to open a URL externally, loading the page\n\n*********")
                UserDefaults.standard.set(nil, forKey: REQUESTED_URL_KEY)
                blockSelf?.loadURL(requestedURL)
            } else {
                guard let arSessionState = blockSelf?.arkController?.arSessionState else { return }
                switch arSessionState {
                    case .arkSessionUnknown:
                        print("\n\n*********\n\nMoving to foreground while ARKit is not initialized, do nothing\n\n*********")
                    case .arkSessionPaused:
                        guard let hasWorldMap = blockSelf?.arkController?.hasBackgroundWorldMap() else { return }
                        if !hasWorldMap {
                            // if no background map, then need to remove anchors on next session
                            print("\n\n*********\n\nMoving to foreground while the session is paused, remember to remove anchors on next AR request\n\n*********")
                            blockSelf?.stateController.state.shouldRemoveAnchorsOnNextARSession = true
                        }
                    case .arkSessionRunning:
                        guard let hasWorldMap = blockSelf?.arkController?.hasBackgroundWorldMap() else { return }
                        if hasWorldMap {
                            print("\n\n*********\n\nMoving to foreground while the session is running and it was in BG\n\n*********")

                            print("\n\n*********\n\nARKit will attempt to relocalize the worldmap automatically\n\n*********")
                        } else {
                            let interruptionDate = UserDefaults.standard.object(forKey: Constant.backgroundOrPausedDateKey()) as? Date
                            let now = Date()
                            if let aDate = interruptionDate {
                                if now.timeIntervalSince(aDate) >= Constant.pauseTimeInSecondsToRemoveAnchors() {
                                    print("\n\n*********\n\nMoving to foreground while the session is running and it was in BG for a long time, remove the anchors\n\n*********")
                                    blockSelf?.arkController?.removeAllAnchors()
                                } else {
                                    print("\n\n*********\n\nMoving to foreground while the session is running and it was in BG for a short time, do nothing\n\n*********")
                                }
                            }
                        }
                }
            }

            UserDefaults.standard.set(nil, forKey: Constant.backgroundOrPausedDateKey())
        }

        stateController.onMemoryWarning = { url in
            blockSelf?.arkController?.controller.previewingSinglePlane = false
//            blockSelf?.chooseSinglePlaneButton.isHidden = true
            blockSelf?.messageController?.showMessageAboutMemoryWarning(withCompletion: {
                blockSelf?.webController?.prefillLastURL()
            })

            blockSelf?.webController?.didReceiveError(error: NSError(domain: MEMORY_ERROR_DOMAIN, code: MEMORY_ERROR_CODE, userInfo: [NSLocalizedDescriptionKey: MEMORY_ERROR_MESSAGE]))
        }

        stateController.onRequestUpdate = { dict in
            defer {
                if dict?[WEB_AR_CV_INFORMATION_OPTION] as? Bool ?? false {
                    blockSelf?.stateController.state.computerVisionFrameRequested = true
                    blockSelf?.arkController?.computerVisionFrameRequested = true
                    blockSelf?.stateController.state.sendComputerVisionData = true
                }
            }
            
            if blockSelf?.timerSessionRunningInBackground != nil {
                print("\n\n*********\n\nInvalidate timer\n\n*********")
                blockSelf?.timerSessionRunningInBackground?.invalidate()
            }

            blockSelf?.savedRender = nil
            blockSelf?.arkController = nil

            if blockSelf?.arkController == nil {
                print("\n\n*********\n\nARKit is nil, instantiate and start a session\n\n*********")
                blockSelf?.startNewARKitSession(withRequest: dict)
            } else {
                guard let arSessionState = blockSelf?.arkController?.arSessionState else { return }
                guard let state = blockSelf?.stateController.state else { return }
                
                if blockSelf?.arkController?.trackingStateRelocalizing() ?? false {
                    blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                    return
                }
                
                switch arSessionState {
                    case .arkSessionUnknown:
                        print("\n\n*********\n\nARKit is in unknown state, instantiate and start a session\n\n*********")
                        blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                    case .arkSessionRunning:
                        if let lastTrackingResetDate = UserDefaults.standard.object(forKey: Constant.lastResetSessionTrackingDateKey()) as? Date,
                            Date().timeIntervalSince(lastTrackingResetDate) >= Constant.thresholdTimeInSecondsSinceLastTrackingReset() {
                            print("\n\n*********\n\nSession is running but it's been a while since last resetting tracking, resetting tracking and removing anchors now to prevent coordinate system drift\n\n*********")
                            blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                        } else if blockSelf?.urlIsNotTheLastXRVisitedURL() ?? false {
                            print("\n\n*********\n\nThis site is not the last XR site visited, and the timer hasn't expired yet. Remove distant anchors and continue with the session\n\n*********")
                            blockSelf?.arkController?.removeDistantAnchors()
                            blockSelf?.arkController?.runSession(with: state)
                        } else {
                            print("\n\n*********\n\nThis site is the last XR site visited, and the timer hasn't expired yet. Continue with the session\n\n*********")
                        }
                    case .arkSessionPaused:
                        print("\n\n*********\n\nRequest of a new AR session when it's paused\n\n*********")
                        guard let shouldRemoveAnchors = blockSelf?.stateController.state.shouldRemoveAnchorsOnNextARSession else { return }
                        if let lastTrackingResetDate = UserDefaults.standard.object(forKey: Constant.lastResetSessionTrackingDateKey()) as? Date,
                            Date().timeIntervalSince(lastTrackingResetDate) >= Constant.thresholdTimeInSecondsSinceLastTrackingReset() {
                            print("\n\n*********\n\nSession is paused and it's been a while since last resetting tracking, resetting tracking and removing anchors on this paused session to prevent coordinate system drift\n\n*********")
                            blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                        } else if shouldRemoveAnchors {
                            print("\n\n*********\n\nRun session removing anchors\n\n*********")
                            blockSelf?.stateController.state.shouldRemoveAnchorsOnNextARSession = false
                            blockSelf?.arkController?.runSessionRemovingAnchors(with: state)
                        } else {
                            print("\n\n*********\n\nResume session\n\n*********")
                            blockSelf?.arkController?.resumeSession(with: state)
                        }
                }
            }
        }
    }
    
//    func setupAnimator() {
//        self.animator = Animator()
//    }
    
    // MARK: - Setup Message Controller
    
    func setupMessageController() {
        self.messageController = MessageController(viewController: browserViewController)

        weak var blockSelf: Tab? = self

        messageController?.didShowMessage = {
            blockSelf?.stateController.saveOnMessageShowMode()
            blockSelf?.stateController.setShowMode(.nothing)
        }

        messageController?.didHideMessage = {
            blockSelf?.stateController.applyOnMessageShowMode()
        }

        messageController?.didHideMessageByUser = {
            //[[blockSelf stateController] applyOnMessageShowMode];
        }
    }
    
    func setupXRNotifications() {
        weak var blockSelf: Tab? = self

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: OperationQueue.main, using: { note in
            blockSelf?.arkController?.controller.previewingSinglePlane = false
//            blockSelf?.chooseSinglePlaneButton.isHidden = true
            var arSessionState: ARKitSessionState
            if blockSelf?.arkController?.arSessionState != nil {
                arSessionState = (blockSelf?.arkController?.arSessionState)!
            } else {
                arSessionState = .arkSessionUnknown
            }
            switch arSessionState {
                case .arkSessionUnknown:
                    print("\n\n*********\n\nMoving to background while ARKit is not initialized, nothing to do\n\n*********")
                case .arkSessionPaused:
                    print("\n\n*********\n\nMoving to background while the session is paused, nothing to do\n\n*********")
                    // need to try and save WorldMap here.  May fail?
                    blockSelf?.arkController?.saveWorldMapInBackground()
                case .arkSessionRunning:
                    print("\n\n*********\n\nMoving to background while the session is running, store the timestamp\n\n*********")
                    UserDefaults.standard.set(Date(), forKey: Constant.backgroundOrPausedDateKey())
                    // need to save WorldMap here
                    blockSelf?.arkController?.saveWorldMapInBackground()
            }

            blockSelf?.webController?.didBackgroundAction(true)

            blockSelf?.stateController.saveMoveToBackground(onURL: blockSelf?.webController?.lastURL)
        })

        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: OperationQueue.main, using: { note in
            blockSelf?.stateController.applyOnEnterForegroundAction()
        })

        NotificationCenter.default.addObserver(self, selector: #selector(Tab.deviceOrientationDidChange(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func deviceOrientationDidChange(_ notification: Notification?) {
        arkController?.shouldUpdateWindowSize = true
        updateConstraints()
    }
    
    // MARK: - Setup Web Controller
    
    func setupXRWebController() {
//        CLEAN_VIEW(v: webLayerView)
        weak var blockSelf: Tab? = self

        self.webController = WebController(rootView: browserViewController?.webViewContainer)
        if !ARKController.supportsARFaceTrackingConfiguration() {
            webController?.hideCameraFlipButton()
        }
//        webController?.animator = animator
        webController?.onStartLoad = {
            if blockSelf?.arkController != nil {
                blockSelf?.arkController?.controller.previewingSinglePlane = false
//                blockSelf?.chooseSinglePlaneButton.isHidden = true
                let lastURL = blockSelf?.webController?.lastURL
                let currentURL = blockSelf?.webController?.webView?.url?.absoluteString

                if lastURL == currentURL {
                    // Page reload
                    blockSelf?.arkController?.removeAllAnchorsExceptPlanes()
                } else {
                    blockSelf?.arkController?.detectionImageCreationPromises.removeAllObjects()
                    blockSelf?.arkController?.detectionImageCreationRequests.removeAllObjects()
                }
                
                if let worldTrackingConfiguration = blockSelf?.arkController?.configuration as? ARWorldTrackingConfiguration,
                    worldTrackingConfiguration.detectionImages.count > 0,
                    let state = blockSelf?.stateController.state
                {
                    worldTrackingConfiguration.detectionImages = Set<ARReferenceImage>()
                    blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
                }
            }
            blockSelf?.arkController?.webXRAuthorizationStatus = .notDetermined
            blockSelf?.stateController.setWebXR(false)
        }

        webController?.onFinishLoad = {
            //         [blockSelf hideSplashWithCompletion:^
            //          { }];
        }
        
        webController?.onInitAR = { uiOptionsDict in
            blockSelf?.stateController.setShowOptions(self.showOptionsFormDict(dict: uiOptionsDict))
            blockSelf?.stateController.applyOnEnterForegroundAction()
            blockSelf?.stateController.applyOnDidReceiveMemoryAction()
            blockSelf?.stateController.state.numberOfTrackedImages = 0
            blockSelf?.arkController?.setNumberOfTrackedImages(0)
            blockSelf?.savedRender = nil
        }

        webController?.onError = { error in
            if let error = error {
//                blockSelf?.showWebError(error as NSError)
            }
        }

        webController?.onWatchAR = { request in
            blockSelf?.handleOnWatchAR(withRequest: request, initialLoad: true, grantedPermissionsBlock: nil)
        }
        
        webController?.onRequestSession = { request, grantedPermissions in
            blockSelf?.handleOnWatchAR(withRequest: request, initialLoad: true, grantedPermissionsBlock: grantedPermissions)
        }
        
        webController?.onJSFinishedRendering = {
            blockSelf?.arkController?.controller.initializingRender = false
            blockSelf?.savedRender?()
            blockSelf?.savedRender = nil
            blockSelf?.arkController?.controller.readyToRenderFrame = true
            if let controller = blockSelf?.arkController?.controller as? ARKMetalController {
                controller.draw(in: controller.renderView)
            }
        }

        webController?.onStopAR = {
            blockSelf?.stateController.setWebXR(false)
            blockSelf?.webController?.userStoppedAR()
        }
        
        webController?.onShowPermissions = {
            blockSelf?.messageController?.forceShowPermissionsPopup = true
            guard let request = blockSelf?.stateController.state.aRRequest else { return }
            blockSelf?.handleOnWatchAR(withRequest: request, initialLoad: false, grantedPermissionsBlock: nil)
        }

        webController?.onJSUpdateData = {
            return blockSelf?.commonData() ?? [:]
        }

        webController?.loadURL = { url in
            blockSelf?.webController?.loadURL(url)
        }

        webController?.onSetUI = { uiOptionsDict in
            blockSelf?.stateController.setShowOptions(self.showOptionsFormDict(dict: uiOptionsDict))
        }

        webController?.onHitTest = { mask, x, y, result in
            if blockSelf?.arkController?.controller.previewingSinglePlane ?? false {
                print("Wait until after Lite Mode plane selected to perform hit tests")
                blockSelf?.deferredHitTest = (mask, x, y, result)
                return
            }
            if blockSelf?.arkController?.webXRAuthorizationStatus == .lite {
                // Default hit testing is done against plane geometry,
                // (HIT_TEST_TYPE_EXISTING_PLANE_GEOMETRY = 32 = 2^5), but to preserve privacy in
                // .lite Mode only hit test against the plane itself
                // (HIT_TEST_TYPE_EXISTING_PLANE = 8 = 2^3)
                var array = [[AnyHashable: Any]]()
                switch blockSelf?.arkController?.interfaceOrientation {
                case .landscapeLeft?:
                    array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: 1-x, y: 1-y), types: 8) ?? []
                case .landscapeRight?:
                    array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: x, y: y), types: 8) ?? []
                default:
                    array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: y, y: 1-x), types: 8) ?? []
                }
                result(array)
            } else {
                var array = [[AnyHashable: Any]]()
                switch blockSelf?.arkController?.interfaceOrientation {
                case .landscapeLeft?:
                    array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: 1-x, y: 1-y), types: mask) ?? []
                case .landscapeRight?:
                    array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: x, y: y), types: mask) ?? []
                default:
                    array = blockSelf?.arkController?.hitTestNormPoint(CGPoint(x: y, y: 1-x), types: mask) ?? []
                }
                result(array)
            }
        }

        webController?.onAddAnchor = { name, transformArray, result in
            if blockSelf?.arkController?.addAnchor(name, transformHash: transformArray) ?? false {
                if let anArray = transformArray {
                    result([WEB_AR_UUID_OPTION: name ?? 0, WEB_AR_TRANSFORM_OPTION: anArray])
                }
            } else {
                result([:])
            }
        }

        webController?.onRemoveObjects = { objects in
            blockSelf?.arkController?.removeAnchors(objects)
        }

        webController?.onDebugButtonToggled = { selected in
            blockSelf?.stateController.setShowMode(selected ? ShowMode.urlDebug : ShowMode.url)
        }
        
        webController?.onGeometryArraysSet = { geometryArrays in
            blockSelf?.stateController.state.geometryArrays = geometryArrays
        }
        
        webController?.onSettingsButtonTapped = {
            // Before showing the settings popup, we hide the bar and the debug buttons so they are not in the way
            // After dismissing the popup, we show them again.
//            let settingsViewController = SettingsViewController()
//            let navigationController = UINavigationController(rootViewController: settingsViewController)
//            weak var weakSettingsViewController = settingsViewController
//            settingsViewController.onDoneButtonTapped = {
//                weakSettingsViewController?.dismiss(animated: true)
//                blockSelf?.webController?.showBar(true)
//                blockSelf?.stateController.setShowMode(.url)
//            }
//
//            blockSelf?.webController?.showBar(false)
//            blockSelf?.webController?.hideKeyboard()
//            blockSelf?.stateController.setShowMode(.nothing)
//            blockSelf?.present(navigationController, animated: true)
        }

        webController?.onComputerVisionDataRequested = {
            blockSelf?.stateController.state.computerVisionFrameRequested = true
            blockSelf?.arkController?.computerVisionFrameRequested = true
        }

        webController?.onResetTrackingButtonTapped = {

//            blockSelf?.messageController?.showMessageAboutResetTracking({ option in
//                guard let state = blockSelf?.stateController.state else { return }
//                switch option {
//                    case .resetTracking:
//                        blockSelf?.arkController?.runSessionResettingTrackingAndRemovingAnchors(with: state)
//                    case .removeExistingAnchors:
//                        blockSelf?.arkController?.runSessionRemovingAnchors(with: state)
//                    case .saveWorldMap:
//                        blockSelf?.arkController?.saveWorldMap()
//                    case .loadSavedWorldMap:
//                        blockSelf?.arkController?.loadSavedMap()
//                }
//            })
        }

        webController?.onStartSendingComputerVisionData = {
            blockSelf?.stateController.state.sendComputerVisionData = true
        }

        webController?.onStopSendingComputerVisionData = {
            blockSelf?.stateController.state.sendComputerVisionData = false
        }
        
        webController?.onSetNumberOfTrackedImages = { number in
            blockSelf?.stateController.state.numberOfTrackedImages = number
            blockSelf?.arkController?.setNumberOfTrackedImages(number)
        }

        webController?.onActivateDetectionImage = { imageName, completion in
            blockSelf?.arkController?.activateDetectionImage(imageName, completion: completion)
        }

        webController?.onGetWorldMap = { completion in
//            let completion = completion as? GetWorldMapCompletionBlock
            blockSelf?.arkController?.getWorldMap(completion)
        }

        webController?.onSetWorldMap = { dictionary, completion in
            blockSelf?.arkController?.setWorldMap(dictionary, completion: completion)
        }

        webController?.onDeactivateDetectionImage = { imageName, completion in
            blockSelf?.arkController?.deactivateDetectionImage(imageName, completion: completion)
        }

        webController?.onDestroyDetectionImage = { imageName, completion in
            blockSelf?.arkController?.destroyDetectionImage(imageName, completion: completion)
        }

        webController?.onCreateDetectionImage = { dictionary, completion in
            blockSelf?.arkController?.createDetectionImage(dictionary, completion: completion)
        }

        webController?.onSwitchCameraButtonTapped = {
//            let numberOfImages = blockSelf?.stateController.state.numberOfTrackedImages ?? 0
//            blockSelf?.arkController?.switchCameraButtonTapped(numberOfImages)
            guard let state = blockSelf?.stateController.state else { return }
            blockSelf?.arkController?.switchCameraButtonTapped(state)
        }

        if stateController.wasMemoryWarning() {
            stateController.applyOnDidReceiveMemoryAction()
        } else {
            let requestedURL = UserDefaults.standard.string(forKey: REQUESTED_URL_KEY)
            if requestedURL != nil && requestedURL != "" {
                UserDefaults.standard.set(nil, forKey: REQUESTED_URL_KEY)
                webController?.loadURL(requestedURL)
            } else {
                let lastURL = UserDefaults.standard.string(forKey: LAST_URL_KEY)
                if lastURL != nil {
                    webController?.loadURL(lastURL)
                } else {
                    let homeURL = UserDefaults.standard.string(forKey: Constant.homeURLKey())
                    if homeURL != nil && homeURL != "" {
                        webController?.loadURL(homeURL)
                    } else {
                        webController?.loadURL(WEB_URL)
                    }
                }
            }
        }
    }
    
    // MARK: Setup Overlay Controller
    
//    func setupOverlayController() {
//        CLEAN_VIEW(v: hotLayerView)
//
//        weak var blockSelf: Tab? = self
//
//        let debugAction: HotAction = { any in
//            blockSelf?.stateController.invertDebugMode()
//        }
//
//        browserViewController?.webViewContainer.processTouchInSubview = true
//
//        self.overlayController = UIOverlayController(rootView: browserViewController?.webViewContainer ?? UIView(), debugAction: debugAction)
//
//        overlayController?.animator = animator
//
//        overlayController?.setMode(stateController.state.showMode)
//        overlayController?.setOptions(stateController.state.showOptions)
//    }
    
    // MARK: - Setup ARK Controller
    
    func setupARKController() {
//        CLEAN_VIEW(v: arkLayerView)

        weak var blockSelf: Tab? = self

        guard let webView = webView else {
            print("Unable to grab tab webView")
            return
        }
        
        arkController = ARKController(type: .arkMetal, rootView: browserViewController?.webViewContainer ?? UIView())

        arkController?.didUpdate = {
            guard let shouldSendNativeTime = blockSelf?.stateController.shouldSendNativeTime() else { return }
            guard let shouldSendARKData = blockSelf?.stateController.shouldSendARKData() else { return }
            guard let shouldSendCVData = blockSelf?.stateController.shouldSendCVData() else { return }
            
            if shouldSendNativeTime {
                blockSelf?.sendNativeTime()
                var numberOfTimesSendNativeTimeWasCalled = blockSelf?.stateController.state.numberOfTimesSendNativeTimeWasCalled
                numberOfTimesSendNativeTimeWasCalled = (numberOfTimesSendNativeTimeWasCalled ?? 0) + 1
                blockSelf?.stateController.state.numberOfTimesSendNativeTimeWasCalled = numberOfTimesSendNativeTimeWasCalled ?? 1
            }

            if shouldSendARKData {
                blockSelf?.sendARKData()
            }

            if shouldSendCVData {
                if blockSelf?.sendComputerVisionData() ?? false {
                    blockSelf?.stateController.state.computerVisionFrameRequested = false
                    blockSelf?.arkController?.computerVisionFrameRequested = false
                }
            }
        }
        arkController?.didChangeTrackingState = { camera in
            
            if let camera = camera,
                let webXR = blockSelf?.stateController.state.webXR,
                webXR
            {
//                blockSelf?.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
//                blockSelf?.updateTrackingStatusIcon(for: camera.trackingState)
//                switch camera.trackingState {
//                case .notAvailable:
//                    return
//                case .limited:
//                    blockSelf?.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
//                case .normal:
//                    blockSelf?.cancelScheduledMessage(forType: .trackingStateEscalation)
//                }
            }
        }
        arkController?.sessionWasInterrupted = {
//            blockSelf?.overlayController?.setARKitInterruption(true)
            blockSelf?.messageController?.showMessageAboutARInterruption(true)
            blockSelf?.webController?.wasARInterruption(true)
        }
        arkController?.sessionInterruptionEnded = {
//            blockSelf?.overlayController?.setARKitInterruption(false)
            blockSelf?.messageController?.showMessageAboutARInterruption(false)
            blockSelf?.webController?.wasARInterruption(false)
        }
        arkController?.didFailSession = { error in
            guard let error = error as NSError? else { return }
            blockSelf?.arkController?.arSessionState = .arkSessionUnknown
            blockSelf?.webController?.didReceiveError(error: error)

            if error.code == SENSOR_FAILED_ARKIT_ERROR_CODE {
                var currentARRequest = blockSelf?.stateController.state.aRRequest
                if currentARRequest?[WEB_AR_WORLD_ALIGNMENT] as? Bool ?? false {
                    // The session failed because the compass (heading) couldn't be initialized. Fallback the session to ARWorldAlignmentGravity
                    currentARRequest?[WEB_AR_WORLD_ALIGNMENT] = false
                    blockSelf?.stateController.setARRequest(currentARRequest ?? [:]) { () -> () in
                        return
                    }
                }
            }

            var errorMessage = "ARKit Error"
            switch error.code {
                case Int(CAMERA_ACCESS_NOT_AUTHORIZED_ARKIT_ERROR_CODE):
                    // If there is a camera access error, do nothing
                    return
                case Int(UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_CODE):
                    errorMessage = UNSUPPORTED_CONFIGURATION_ARKIT_ERROR_MESSAGE
                case Int(SENSOR_UNAVAILABLE_ARKIT_ERROR_CODE):
                    errorMessage = SENSOR_UNAVAILABLE_ARKIT_ERROR_MESSAGE
                case Int(SENSOR_FAILED_ARKIT_ERROR_CODE):
                    errorMessage = SENSOR_FAILED_ARKIT_ERROR_MESSAGE
                case Int(WORLD_TRACKING_FAILED_ARKIT_ERROR_CODE):
                    errorMessage = WORLD_TRACKING_FAILED_ARKIT_ERROR_MESSAGE
                default:
                    break
            }

            DispatchQueue.main.async(execute: {
                blockSelf?.messageController?.hideMessages()
                blockSelf?.messageController?.showMessageAboutFailSession(withMessage: errorMessage) {
                    DispatchQueue.main.async(execute: {
                        self.webController?.prefillLastURL()
                    })
                }
            })
        }

        arkController?.didUpdateWindowSize = {
            blockSelf?.webController?.updateWindowSize()
        }

//        animator?.animate(browserViewController?.webViewContainer, toFade: false)

        arkController?.startSession(with: stateController.state)
        
        arkController?.controller.renderer.rendererShouldUpdateFrame = { block in
            if let frame = blockSelf?.arkController?.session.currentFrame {
                blockSelf?.arkController?.controller.readyToRenderFrame = false
                blockSelf?.savedRender = block 
                blockSelf?.arkController?.updateARKData(with: frame)
                blockSelf?.arkController?.didUpdate?()
            } else {
                print("Unable to updateARKData since ARFrame isn't ready")
                block()
            }
        }

        // Log event when we start an AR session
//        AnalyticsManager.sharedInstance.sendEvent(category: .action, method: .webXR, object: .initialize)
    }
    
    func handleOnWatchAR(withRequest request: [AnyHashable : Any], initialLoad: Bool, grantedPermissionsBlock: ResultBlock?) {
        weak var blockSelf: Tab? = self

        if initialLoad {
            arkController?.computerVisionDataEnabled = false
            stateController.state.userGrantedSendingComputerVisionData = false
            stateController.state.userGrantedSendingWorldStateData = .notDetermined
            stateController.state.sendComputerVisionData = false
            stateController.state.askedComputerVisionData = false
            stateController.state.askedWorldStateData = false
        }
        
        guard let url = webController?.webView?.url else {
            grantedPermissionsBlock?([ "error" : "no web page loaded, should not happen"])
            return
        }
        arkController?.controller.previewingSinglePlane = false
        if let arController = arkController?.controller as? ARKMetalController {
            arController.focusedPlane = nil
        }
//        else if let arController = arkController?.controller as? ARKSceneKitController {
//            arController.focusedPlane = nil
//        }
//        chooseSinglePlaneButton.isHidden = true

        stateController.state.numberOfTimesSendNativeTimeWasCalled = 0
        stateController.setARRequest(request) { () -> () in
            if request[WEB_AR_CV_INFORMATION_OPTION] as? Bool ?? false {
                blockSelf?.messageController?.showMessageAboutEnteringXR(.videoCameraAccess, authorizationGranted: { access in
                    
                    blockSelf?.arkController?.geometryArrays = blockSelf?.stateController.state.geometryArrays ?? false
                    blockSelf?.stateController.state.askedComputerVisionData = true
                    blockSelf?.stateController.state.askedWorldStateData = true
                    let grantedCameraAccess = access == .videoCameraAccess ? true : false
                    let grantedWorldAccess = (access == .videoCameraAccess || access == .worldSensing || access == .lite) ? true : false
                    
                    blockSelf?.arkController?.computerVisionDataEnabled = grantedCameraAccess
                    
                    // Approving computer vision data implicitly approves the world sensing data
                    blockSelf?.arkController?.webXRAuthorizationStatus = access
                    
                    blockSelf?.stateController.state.userGrantedSendingComputerVisionData = grantedCameraAccess
                    blockSelf?.stateController.state.userGrantedSendingWorldStateData = access
                    
                    switch access {
                    case .minimal, .lite, .worldSensing, .videoCameraAccess:
                        blockSelf?.stateController.setWebXR(true)
                    default:
                        blockSelf?.stateController.setWebXR(false)
                    }
                    blockSelf?.webController?.userGrantedWebXRAuthorizationState(access)
                    let permissions = [
                        "cameraAccess": grantedCameraAccess,
                        "worldAccess": grantedWorldAccess,
                        "webXRAccess": blockSelf?.stateController.state.webXR ?? false
                    ]
                    grantedPermissionsBlock?(permissions)
                }, url: url)
            } else if request[WEB_AR_WORLD_SENSING_DATA_OPTION] as? Bool ?? false {
                blockSelf?.messageController?.showMessageAboutEnteringXR(.worldSensing, authorizationGranted: { access in
                    
                    blockSelf?.arkController?.geometryArrays = blockSelf?.stateController.state.geometryArrays ?? false
                    blockSelf?.stateController.state.askedWorldStateData = true
                    blockSelf?.arkController?.webXRAuthorizationStatus = access
                    blockSelf?.stateController.state.userGrantedSendingWorldStateData = access
                    let grantedWorldAccess = (access == .worldSensing || access == .lite) ? true : false
                    
                    switch access {
                    case .minimal, .lite, .worldSensing, .videoCameraAccess:
                        blockSelf?.stateController.setWebXR(true)
                    default:
                        blockSelf?.stateController.setWebXR(false)
                    }
                    
                    blockSelf?.webController?.userGrantedWebXRAuthorizationState(access)
                    let permissions = [
                        "cameraAccess": false,
                        "worldAccess": grantedWorldAccess,
                        "webXRAccess": blockSelf?.stateController.state.webXR ?? false
                    ]
                    grantedPermissionsBlock?(permissions)
                    
                    if access == .lite {
                        blockSelf?.arkController?.controller.previewingSinglePlane = true
//                        blockSelf?.chooseSinglePlaneButton.isHidden = false
                        if blockSelf?.stateController.state.shouldShowLiteModePopup ?? false {
                            blockSelf?.stateController.state.shouldShowLiteModePopup = false
                            blockSelf?.messageController?.showMessage(withTitle: "Lite Mode Started", message: "Choose one plane to share with this website.", hideAfter: 2)
                        }
                    }
                }, url: url)
            } else {
                // if neither is requested, we'll request .minimal WebXR authorization!
                blockSelf?.messageController?.showMessageAboutEnteringXR(.minimal, authorizationGranted: { access in
                    
                    blockSelf?.arkController?.geometryArrays = blockSelf?.stateController.state.geometryArrays ?? false
                    blockSelf?.arkController?.webXRAuthorizationStatus = access
                    
                    switch access {
                    case .minimal, .lite, .worldSensing, .videoCameraAccess:
                        blockSelf?.stateController.setWebXR(true)
                    case .denied, .notDetermined:
                        blockSelf?.stateController.setWebXR(false)
                    }
                    
                    blockSelf?.webController?.userGrantedWebXRAuthorizationState(access)
                    let permissions = [
                        "cameraAccess": false,
                        "worldAccess": false,
                        "webXRAccess": blockSelf?.stateController.state.webXR ?? false
                    ]
                    grantedPermissionsBlock?(permissions)
                    
                    if access == .lite {
                        blockSelf?.arkController?.controller.previewingSinglePlane = true
//                        blockSelf?.chooseSinglePlaneButton.isHidden = false
                        if blockSelf?.stateController.state.shouldShowLiteModePopup ?? false {
                            blockSelf?.stateController.state.shouldShowLiteModePopup = false
                            blockSelf?.messageController?.showMessage(withTitle: "Lite Mode Started", message: "Choose one plane to share with this website.", hideAfter: 2)
                        }
                    }
                }, url: url)
            }
        }
    }
    
    func commonData() -> [AnyHashable : Any] {
        var dictionary = [AnyHashable : Any]()

        if let aData = arkController?.getARKData() {
            dictionary = aData
        }

        return dictionary
//        return arkController?.getARKData() ?? [:]
    }
    
    func loadURL(_ url: String?) {
        if url == nil {
            webController?.reload()
        } else {
            webController?.loadURL(url)
        }

        stateController.setWebXR(false)
    }
    
    func urlIsNotTheLastXRVisitedURL() -> Bool {
        return !(webController?.webView?.url?.absoluteString == webController?.lastXRVisitedURL)
    }
    
    func startNewARKitSession(withRequest request: [AnyHashable : Any]?) {
//        setupLocationController()
//        locationManager?.setup(forRequest: request)
        setupARKController()
    }
    
    func sendNativeTime() {
        guard let currentFrame = arkController?.currentFrameTimeInMilliseconds() else { return }
        webController?.sendNativeTime(currentFrame)
    }
    
    func sendComputerVisionData() -> Bool {
        if let data = arkController?.getComputerVisionData() {
            webController?.sendComputerVisionData(data)
            return true
        }
        return false
    }
    
    func sendARKData() {
        webController?.sendARData(arkController?.getARKData() ?? [:])
    }
    
    private func showOptionsFormDict(dict: [AnyHashable : Any]?) -> ShowOptions {
        if dict == nil {
            return .browser
        }
        
        var options: ShowOptions = .init(rawValue: 0)
        
        if (dict?[WEB_AR_UI_BROWSER_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .browser]
        }
        
        if (dict?[WEB_AR_UI_POINTS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arPoints]
        }
        
        if (dict?[WEB_AR_UI_DEBUG_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .debug]
        }
        
        if (dict?[WEB_AR_UI_STATISTICS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arStatistics]
        }
        
        if (dict?[WEB_AR_UI_FOCUS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arFocus]
        }
        
        if (dict?[WEB_AR_UI_BUILD_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .buildNumber]
        }
        
        if (dict?[WEB_AR_UI_PLANE_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arPlanes]
        }
        
        if (dict?[WEB_AR_UI_WARNINGS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arWarnings]
        }
        
        if (dict?[WEB_AR_UI_ANCHORS_OPTION] as? NSNumber)?.boolValue ?? false {
            options = [options, .arObject]
        }
        
        return options
    }
    
    func updateConstraints() {
//        guard let barViewHeight = webController?.barViewHeightAnchorConstraint else { return }
        guard let webViewTop = webController?.webViewTopAnchorConstraint else { return }
        guard let webViewLeft = webController?.webViewLeftAnchorConstraint else { return }
        guard let webViewRight = webController?.webViewRightAnchorConstraint else { return }
        let webXR = stateController.state.webXR
        // If XR is active, then the top anchor is 0 (fullscreen), else topSafeAreaInset + Constant.urlBarHeight()
        let topSafeAreaInset = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? 0.0
//        barViewHeight.constant = topSafeAreaInset + Constant.urlBarHeight()
        webViewTop.constant = webXR ? 0.0 : topSafeAreaInset + Constant.urlBarHeight()

        webViewLeft.constant = 0.0
        webViewRight.constant = 0.0
        if !stateController.state.webXR {
            let currentOrientation: UIInterfaceOrientation = Utils.getInterfaceOrientationFromDeviceOrientation()
            if currentOrientation == .landscapeLeft {
                // The notch is to the right
                let rightSafeAreaInset = UIApplication.shared.keyWindow?.safeAreaInsets.right ?? 0.0
                webViewRight.constant = webXR ? 0.0 : -rightSafeAreaInset
            } else if currentOrientation == .landscapeRight {
                // The notch is to the left
                let leftSafeAreaInset = CGFloat(UIApplication.shared.keyWindow?.safeAreaInsets.left ?? 0.0)
                webViewLeft.constant = leftSafeAreaInset
            }
        }

        webView?.setNeedsLayout()
        webView?.layoutIfNeeded()
    }
}
#endif
