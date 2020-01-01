import Foundation
import WebKit
import XCGLogger
import Shared

typealias ResultBlock = ([AnyHashable : Any]?) -> Void
typealias ResultArrayBlock = ([Any]?) -> Void
typealias ImageDetectedBlock = ([AnyHashable : Any]?) -> Void
typealias ActivateDetectionImageCompletionBlock = (Bool, String?, [AnyHashable : Any]?) -> Void
typealias CreateDetectionImageCompletionBlock = (Bool, String?) -> Void
typealias GetWorldMapCompletionBlock = (Bool, String?, [AnyHashable : Any]?) -> Void
typealias SetWorldMapCompletionBlock = (Bool, String?) -> Void
typealias WebCompletion = (Any?, Error?) -> Void
private let log = Logger.browserLogger

class WebController: NSObject,
//WKUIDelegate, WKNavigationDelegate,
WKScriptMessageHandler {
    var onInitAR: (([AnyHashable : Any]?) -> Void)?
    var onError: ((Error?) -> Void)?
    var loadURL: ((String?) -> Void)?
    var onJSUpdateData: (() -> [AnyHashable : Any])?
    var onRemoveObjects: (([Any]) -> Void)?
    var onSetUI: (([AnyHashable : Any]?) -> Void)?
    var onHitTest: ((Int, CGFloat, CGFloat, @escaping ResultArrayBlock) -> Void)?
    var onAddAnchor: ((String?, [AnyHashable: Any]?, @escaping ResultBlock) -> Void)?
    var onStartLoad: (() -> Void)?
    var onFinishLoad: (() -> Void)?
    var onDebugButtonToggled: ((Bool) -> Void)?
    var onGeometryArraysSet: ((Bool) -> Void)?
    var onSettingsButtonTapped: (() -> Void)?
    var onWatchAR: (([AnyHashable : Any]) -> Void)?
    var onRequestSession: (([AnyHashable: Any], @escaping ResultBlock) -> Void)?
    var onJSFinishedRendering: (() -> Void)?
    var onComputerVisionDataRequested: (() -> Void)?
    var onStopAR: (() -> Void)?
    var onResetTrackingButtonTapped: (() -> Void)?
    var onSwitchCameraButtonTapped: (() -> Void)?
    var onShowPermissions: (() -> Void)?
    var onStartSendingComputerVisionData: (() -> Void)?
    var onStopSendingComputerVisionData: (() -> Void)?
    var onSetNumberOfTrackedImages: ((Int) -> Void)?
    var onAddImageAnchor: (([AnyHashable : Any]?, @escaping ImageDetectedBlock) -> Void)?
    var onActivateDetectionImage: ((String?, @escaping ActivateDetectionImageCompletionBlock) -> Void)?
    var onDeactivateDetectionImage: ((String, @escaping CreateDetectionImageCompletionBlock) -> Void)?
    var onDestroyDetectionImage: ((String, @escaping CreateDetectionImageCompletionBlock) -> Void)?
    var onCreateDetectionImage: (([AnyHashable : Any], @escaping CreateDetectionImageCompletionBlock) -> Void)?
    var onGetWorldMap: ((@escaping GetWorldMapCompletionBlock) -> Void)?
    var onSetWorldMap: (([AnyHashable : Any], @escaping SetWorldMapCompletionBlock) -> Void)?
//    weak var barViewHeightAnchorConstraint: NSLayoutConstraint?
    weak var webViewTopAnchorConstraint: NSLayoutConstraint?
    var webViewLeftAnchorConstraint: NSLayoutConstraint?
    var webViewRightAnchorConstraint: NSLayoutConstraint?
    var lastXRVisitedURL = ""

    func hideCameraFlipButton() {
//        barView?.hideCameraFlipButton()
    }
    private weak var rootView: UIView?
    weak var webView: TabWebView?
    private weak var contentController: WKUserContentController?
    private var transferCallback = ""
    var lastURL = ""
//    weak var barView: BarView?
//    private weak var barViewTopAnchorConstraint: NSLayoutConstraint?
    private var documentReadyState = ""
    
    init(rootView: UIView?) {

        super.init()
//        self.webView?.navigationDelegate = self
//        self.webView?.uiDelegate = self
        setupWebView(withRootView: rootView)
        setupWebContent()
        setupWebUI()
//        setupBarView()
    }
    
    deinit {
        log.debug("WebController dealloc")
    }

    func viewWillTransition(to size: CGSize) {
        layout()

        // This message is not being used by the polyfyill
        // [self callWebMethod:WEB_AR_IOS_VIEW_WILL_TRANSITION_TO_SIZE_MESSAGE param:NSStringFromCGSize(size) webCompletion:debugCompletion(@"viewWillTransitionToSize")];
    }

    func loadURL(_ theUrl: String?) {
        goFullScreen()

        var url: URL?
        if theUrl?.hasPrefix("http://") ?? false || theUrl?.hasPrefix("https://") ?? false {
            url = URL(string: theUrl ?? "")
        } else {
            url = URL(string: "https://\(theUrl ?? "")")
        }

        if url != nil {
            let scheme = url?.scheme

            if scheme != nil && WKWebView.handlesURLScheme(scheme ?? "") {
                var r: URLRequest? = nil
                if let anUrl = url {
                    r = URLRequest(url: anUrl, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 60)
                }

                URLCache.shared.removeAllCachedResponses()

                if let aR = r {
                    webView?.load(aR)
                }

                self.lastURL = url?.absoluteString ?? ""
                return
            }
        }
        //if onError
        onError?(nil)
    }

    func prefillLastURL() {
//        barView?.urlField.text = UserDefaults.standard.string(forKey: LAST_URL_KEY)
    }

    func reload() {
//        let url = (barView?.urlFieldText()?.count ?? 0) > 0 ? barView?.urlFieldText() : lastURL
//        loadURL(url)
    }

    func clean() {
        cleanWebContent()

        webView?.stopLoading()

        webView?.configuration.processPool = WKProcessPool()
        URLCache.shared.removeAllCachedResponses()
    }

    func setup(forWebXR webXR: Bool) {
        DispatchQueue.main.async(execute: {
//            self.barView?.hideKeyboard()
//            self.barView?.setDebugVisible(webXR)
//            self.barView?.setRestartTrackingVisible(webXR)
            let webViewTopAnchorConstraintConstant: Float = webXR ? 0.0 : Float(Constant.urlBarHeight())
            self.webViewTopAnchorConstraint?.constant = CGFloat(webViewTopAnchorConstraintConstant)
            self.webView?.superview?.setNeedsLayout()
            self.webView?.superview?.layoutIfNeeded()

            let backColor = webXR ? UIColor.clear : UIColor.white
            self.webView?.superview?.backgroundColor = backColor
        })
    }

    func showBar(_ showBar: Bool) {
        print("Show bar: \(showBar ? "Yes" : "No")")
//        barView?.superview?.layoutIfNeeded()

//        let topAnchorConstant: Float = showBar ? 0.0 : Float(0.0 - Constant.urlBarHeight() * 2)
//        barViewTopAnchorConstraint?.constant = CGFloat(topAnchorConstant)

        UIView.animate(withDuration: Constant.urlBarAnimationTimeInSeconds(), animations: {
//            self.barView?.superview?.layoutIfNeeded()
        })
    }

    func showDebug(_ showDebug: Bool) {
        callWebMethod(WEB_AR_IOS_SHOW_DEBUG, paramJSON: [WEB_AR_UI_DEBUG_OPTION: showDebug ? true : false], webCompletion: debugCompletion(name: "showDebug"))
    }

    func wasARInterruption(_ interruption: Bool) {
        let message = interruption ? WEB_AR_IOS_START_RECORDING_MESSAGE : WEB_AR_IOS_INTERRUPTION_ENDED_MESSAGE

        callWebMethod(message, param: "", webCompletion: debugCompletion(name: "ARinterruption"))
    }

    func didBackgroundAction(_ background: Bool) {
        let message = background ? WEB_AR_IOS_DID_MOVE_BACK_MESSAGE : WEB_AR_IOS_WILL_ENTER_FOR_MESSAGE

        callWebMethod(message, param: "", webCompletion: debugCompletion(name: "backgroundAction"))
    }

    func didChangeARTrackingState(_ state: String?) {
        callWebMethod(WEB_AR_IOS_TRACKING_STATE_MESSAGE, param: state, webCompletion: debugCompletion(name: "arkitDidChangeTrackingState"))
    }

    func updateWindowSize() {
        let size: CGSize? = webView?.frame.size
        let sizeDictionary = [WEB_AR_IOS_SIZE_WIDTH_PARAMETER: size?.width ?? 0, WEB_AR_IOS_SIZE_HEIGHT_PARAMETER: size?.height ?? 0]
        callWebMethod(WEB_AR_IOS_WINDOW_RESIZE_MESSAGE, paramJSON: sizeDictionary, webCompletion: debugCompletion(name: WEB_AR_IOS_WINDOW_RESIZE_MESSAGE))
    }

    func didReceiveMemoryWarning() {
        callWebMethod(WEB_AR_IOS_DID_RECEIVE_MEMORY_WARNING_MESSAGE, param: "", webCompletion: debugCompletion(name: "iosDidReceiveMemoryWarning"))
    }

    func sendARData(_ data: [AnyHashable : Any]) {
        if transferCallback != ""  {
            callWebMethod(transferCallback, paramJSON: data, webCompletion: nil)
        }
    }
    
    func userStoppedAR() {
        callWebMethod(WEB_AR_IOS_USERSTOPPED_AR, param: "", webCompletion: nil)
    }

    func hideKeyboard() {
//        barView?.hideKeyboard()
    }

    func didReceiveError(error: NSError) {
        let errorDictionary = [WEB_AR_IOS_ERROR_DOMAIN_PARAMETER: error.domain, WEB_AR_IOS_ERROR_CODE_PARAMETER: error.code, WEB_AR_IOS_ERROR_MESSAGE_PARAMETER: error.localizedDescription] as [String : Any]
        callWebMethod(WEB_AR_IOS_ERROR_MESSAGE, paramJSON: errorDictionary, webCompletion: debugCompletion(name: WEB_AR_IOS_ERROR_MESSAGE))
    }

    func sendComputerVisionData(_ computerVisionData: [AnyHashable : Any]) {
        callWebMethod("onComputerVisionData", paramJSON: computerVisionData, webCompletion: { param, error in
            if error != nil {
                print("Error onComputerVisionData: \(error?.localizedDescription ?? "")")
            }
        })
    }

    func isDebugButtonSelected() -> Bool {
//        return barView?.isDebugButtonSelected() ?? false
        return false
    }

    func sendNativeTime(_ nativeTime: TimeInterval) {
        print("Sending native time: \(nativeTime)")
        let jsonData = ["nativeTime": nativeTime]
        callWebMethod("setNativeTime", paramJSON: jsonData, webCompletion: { param, error in
            if error != nil {
                print("Error setNativeTime: \(error?.localizedDescription ?? "")")
            }
        })
    }

    func userGrantedWebXRAuthorizationState(_ access: WebXRAuthorizationState) {
//        barView?.permissionLevelButton?.isEnabled = true
//        switch access {
//        case .videoCameraAccess:
//            let image = UIImage(named: "camera")
//            let tintedImage = image?.withRenderingMode(.alwaysTemplate)
//            barView?.permissionLevelButton?.setImage(tintedImage, for: .normal)
//            barView?.permissionLevelButton?.tintColor = .red
//        case .worldSensing:
//            let image = UIImage(named: "globe")
//            let tintedImage = image?.withRenderingMode(.alwaysTemplate)
//            barView?.permissionLevelButton?.setImage(tintedImage, for: .normal)
//            barView?.permissionLevelButton?.tintColor = .red
//        case .lite:
//            let image = UIImage(named: "view_off")
//            let tintedImage = image?.withRenderingMode(.alwaysTemplate)
//            barView?.permissionLevelButton?.setImage(tintedImage, for: .normal)
//            barView?.permissionLevelButton?.tintColor = .red
//        case .minimal:
//            let image = UIImage(named: "circle_ok")
//            let tintedImage = image?.withRenderingMode(.alwaysTemplate)
//            barView?.permissionLevelButton?.setImage(tintedImage, for: .normal)
//            barView?.permissionLevelButton?.tintColor = .green
//        case .denied:
//            let image = UIImage(named: "block")
//            let tintedImage = image?.withRenderingMode(.alwaysTemplate)
//            barView?.permissionLevelButton?.setImage(tintedImage, for: .normal)
//            barView?.permissionLevelButton?.tintColor = .green
//        case .notDetermined:
//            barView?.permissionLevelButton?.setImage(nil, for: .normal)
//            barView?.permissionLevelButton?.isEnabled = false
//        }
        
        // This may change, in one of two ways:
        // - should probably switch this to one method that updates all aspects of the state we want
        // the page to know
        // - may want to remove entirely: do we even need to notify the page what the current state is?
        switch access {
        case .videoCameraAccess:
            callWebMethod(WEB_AR_IOS_USER_GRANTED_CV_DATA, paramJSON: ["granted": true], webCompletion: debugCompletion(name: WEB_AR_IOS_USER_GRANTED_CV_DATA))
            callWebMethod(WEB_AR_IOS_USER_GRANTED_WORLD_SENSING_DATA, paramJSON: ["granted": false], webCompletion: debugCompletion(name: WEB_AR_IOS_USER_GRANTED_WORLD_SENSING_DATA))
        case .worldSensing, .lite:
            callWebMethod(WEB_AR_IOS_USER_GRANTED_CV_DATA, paramJSON: ["granted": false], webCompletion: debugCompletion(name: WEB_AR_IOS_USER_GRANTED_CV_DATA))
            callWebMethod(WEB_AR_IOS_USER_GRANTED_WORLD_SENSING_DATA, paramJSON: ["granted": true], webCompletion: debugCompletion(name: WEB_AR_IOS_USER_GRANTED_WORLD_SENSING_DATA))
        case .notDetermined, .minimal, .denied:
            callWebMethod(WEB_AR_IOS_USER_GRANTED_CV_DATA, paramJSON: ["granted": false], webCompletion: debugCompletion(name: WEB_AR_IOS_USER_GRANTED_CV_DATA))
            callWebMethod(WEB_AR_IOS_USER_GRANTED_WORLD_SENSING_DATA, paramJSON: ["granted": false], webCompletion: debugCompletion(name: WEB_AR_IOS_USER_GRANTED_WORLD_SENSING_DATA))
        }
    }

    func goHome() {
        print("going home")
        let homeURL = UserDefaults.standard.string(forKey: Constant.homeURLKey())
        if homeURL != nil && !(homeURL == "") {
            loadURL(homeURL)
        } else {
            loadURL(WEB_URL)
        }
    }

    // MARK: WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        weak var blockSelf: WebController? = self
        guard let messageBody = message.body as? [String: Any] else { return }
        if message.name == WEB_AR_INIT_MESSAGE {
            let params = [
                WEB_IOS_DEVICE_UUID_OPTION: UIDevice.current.identifierForVendor?.uuidString ?? 0,
                WEB_IOS_IS_IPAD_OPTION: UIDevice.current.userInterfaceIdiom == .pad,
                WEB_IOS_SYSTEM_VERSION_OPTION: UIDevice.current.systemVersion,
                WEB_IOS_SCREEN_SCALE_OPTION: UIScreen.main.nativeScale,
                WEB_IOS_SCREEN_SIZE_OPTION: NSCoder.string(for: UIScreen.main.nativeBounds.size)
            ] as [String : Any]

            log.debug("Init AR send - \(params.debugDescription)")
            guard let name = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            callWebMethod(name, paramJSON: params, webCompletion: { param, error in

                if error == nil {
                    log.debug("Init AR Success")
                    guard let arRequestOption = messageBody[WEB_AR_REQUEST_OPTION] as? [String: Any] else { return }
                    guard let arUIOption = arRequestOption[WEB_AR_UI_OPTION] as? [String: Any] else { return }
                    let geometryArrays = arRequestOption[WEB_AR_GEOMETRY_ARRAYS] as? Bool ?? false
                    blockSelf?.onGeometryArraysSet?(geometryArrays)
                    blockSelf?.onInitAR?(arUIOption)
                } else {
                    log.debug("Init AR Error")
                    blockSelf?.onError?(error)
                }
            })
        } else if message.name == WEB_AR_INJECT_POLYFILL {
            let scriptBundle = Bundle(for: WebController.self)
            let scriptURL = scriptBundle.path(forResource: "webxrPolyfill", ofType: "js")
            let scriptContent = try? String(contentsOfFile: scriptURL ?? "", encoding: .utf8)
            let userScript = WKUserScript(source: scriptContent ?? "", injectionTime: .atDocumentStart, forMainFrameOnly: true)
            contentController?.addUserScript(userScript)
        } else if message.name == WEB_AR_LOAD_URL_MESSAGE {
            loadURL?(messageBody[WEB_AR_URL_OPTION] as? String)
        } else if message.name == WEB_AR_START_WATCH_MESSAGE {
            self.transferCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String ?? ""

            onWatchAR?(messageBody[WEB_AR_REQUEST_OPTION] as? [AnyHashable: Any] ?? [:])
        } else if message.name == WEB_AR_REQUEST_MESSAGE {
            guard let requestSessionCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            guard let transferCallback = messageBody[WEB_AR_DATA_CALLBACK_OPTION] as? String else {
                var responseDictionary = [AnyHashable : Any]()
                responseDictionary["error"] = "not data_callback parameter"
                blockSelf?.callWebMethod(requestSessionCallback, paramJSON: responseDictionary, webCompletion: debugCompletion(name: "requestSession"))
                return
            }
            self.transferCallback = transferCallback
            onRequestSession?(messageBody[WEB_AR_REQUEST_OPTION] as? [AnyHashable: Any] ?? [:], { permissions in
                blockSelf?.callWebMethod(requestSessionCallback, paramJSON: permissions, webCompletion: debugCompletion(name: "onRequestSession"))
            })
        } else if message.name == WEB_AR_ON_JS_UPDATE_MESSAGE {
            onJSFinishedRendering?()
        } else if message.name == WEB_AR_STOP_WATCH_MESSAGE {
            self.transferCallback = ""

            onStopAR?()
            guard let name = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            callWebMethod(name, param: "", webCompletion: nil)
        } else if message.name == WEB_AR_SET_UI_MESSAGE {
            onSetUI?(messageBody)
        } else if message.name == WEB_AR_HIT_TEST_MESSAGE {
            guard let hitCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            let type = Int(messageBody[WEB_AR_TYPE_OPTION] as? Int ?? 0)
            let x = CGFloat(messageBody[WEB_AR_X_POSITION_OPTION] as? CGFloat ?? 0.0)
            let y = CGFloat(messageBody[WEB_AR_Y_POSITION_OPTION] as? CGFloat ?? 0.0)

            onHitTest?(type, x, y, { results in
                blockSelf?.callWebMethod(hitCallback, paramJSON: results, webCompletion: debugCompletion(name: "onHitTest"))
            })
        } else if message.name == WEB_AR_ADD_ANCHOR_MESSAGE {
            guard let hitCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            let name = messageBody[WEB_AR_UUID_OPTION] as? String
            guard let transform = messageBody[WEB_AR_TRANSFORM_OPTION] as? [AnyHashable: Any] else {
                var responseDictionary = [AnyHashable : Any]()
                responseDictionary["error"] = "invalid transform parameter"
                blockSelf?.callWebMethod(hitCallback, paramJSON: responseDictionary, webCompletion: debugCompletion(name: "onAddAnchor"))
                return
            }
            onAddAnchor?(name, transform, { results in
                blockSelf?.callWebMethod(hitCallback, paramJSON: results, webCompletion: debugCompletion(name: "onAddAnchor"))
            })
        } else if message.name == WEB_AR_REQUEST_CV_DATA_MESSAGE {
            onComputerVisionDataRequested?()
        } else if message.name == WEB_AR_START_SENDING_CV_DATA_MESSAGE {
            onStartSendingComputerVisionData?()
        } else if message.name == WEB_AR_STOP_SENDING_CV_DATA_MESSAGE {
            onStopSendingComputerVisionData?()
        } else if message.name == WEB_AR_REMOVE_ANCHORS_MESSAGE {
            guard let anchorIDs = message.body as? [Any] else { return }
            onRemoveObjects?(anchorIDs)
        } else if message.name == WEB_AR_ADD_IMAGE_ANCHOR {
            let imageAnchorInfoDictionary = messageBody
            guard let createImageAnchorCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            onAddImageAnchor?(imageAnchorInfoDictionary, { imageAnchor in
                blockSelf?.callWebMethod(createImageAnchorCallback, paramJSON: imageAnchor, webCompletion: nil)
            })
        } else if message.name == WEB_AR_TRACKED_IMAGES_MESSAGE {
            let numberOfTrackedImages = messageBody[WEB_AR_NUMBER_OF_TRACKED_IMAGES_OPTION] as? Int ?? 0
            onSetNumberOfTrackedImages?(numberOfTrackedImages)
        } else if message.name == WEB_AR_CREATE_IMAGE_ANCHOR_MESSAGE {
            let imageAnchorInfoDictionary = messageBody
            guard let createDetectionImageCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            onCreateDetectionImage?(imageAnchorInfoDictionary, { success, errorString in
                var responseDictionary = [String : Any]()
                responseDictionary["created"] = success
                if errorString != nil {
                    responseDictionary["error"] = errorString
                }
                blockSelf?.callWebMethod(createDetectionImageCallback, paramJSON: responseDictionary, webCompletion: nil)
            })
        } else if message.name == WEB_AR_ACTIVATE_DETECTION_IMAGE_MESSAGE {
            let imageAnchorInfoDictionary = messageBody
            let imageName = imageAnchorInfoDictionary[WEB_AR_DETECTION_IMAGE_NAME_OPTION] as? String
            guard let activateDetectionImageCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            onActivateDetectionImage?(imageName, { success, errorString, imageAnchor in
                var responseDictionary = [AnyHashable : Any]()
                responseDictionary["activated"] = success
                if errorString != nil {
                    responseDictionary["error"] = errorString ?? ""
                } else {
                    if let anAnchor = imageAnchor {
                        responseDictionary["imageAnchor"] = anAnchor
                    }
                }
                blockSelf?.callWebMethod(activateDetectionImageCallback, paramJSON: responseDictionary, webCompletion: nil)
            })
        } else if message.name == WEB_AR_DEACTIVATE_DETECTION_IMAGE_MESSAGE {
            let imageAnchorInfoDictionary = messageBody
            guard let deactivateDetectionImageCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            guard let imageName = imageAnchorInfoDictionary[WEB_AR_DETECTION_IMAGE_NAME_OPTION] as? String else {
                var responseDictionary = [AnyHashable : Any]()
                responseDictionary["error"] = "invalid image name parameter"
                blockSelf?.callWebMethod(deactivateDetectionImageCallback, paramJSON: responseDictionary, webCompletion: debugCompletion(name: "onDeactivateImage"))
                return
            }

            onDeactivateDetectionImage?(imageName, { success, errorString in
                var responseDictionary = [AnyHashable : Any]()
                responseDictionary["deactivated"] = success
                if errorString != nil {
                    responseDictionary["error"] = errorString ?? ""
                }
                blockSelf?.callWebMethod(deactivateDetectionImageCallback, paramJSON: responseDictionary, webCompletion: debugCompletion(name: "onDeactivateImage"))
            })
        } else if message.name == WEB_AR_DESTROY_DETECTION_IMAGE_MESSAGE {
            let imageAnchorInfoDictionary = messageBody
            guard let destroyDetectionImageCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            guard let imageName = imageAnchorInfoDictionary[WEB_AR_DETECTION_IMAGE_NAME_OPTION] as? String else {
                var responseDictionary = [AnyHashable : Any]()
                responseDictionary["error"] = "invalid image name parameter"
                blockSelf?.callWebMethod(destroyDetectionImageCallback, paramJSON: responseDictionary, webCompletion: debugCompletion(name: "onDestroyDetectionImage"))
                return
            }
            onDestroyDetectionImage?(imageName, { success, errorString in
                var responseDictionary = [AnyHashable : Any]()
                responseDictionary["destroyed"] = success
                if errorString != nil {
                    responseDictionary["error"] = errorString ?? ""
                }
                blockSelf?.callWebMethod(destroyDetectionImageCallback, paramJSON: responseDictionary, webCompletion: debugCompletion(name: "onDestroyDetectionImage"))
            })
        } else if message.name == WEB_AR_GET_WORLD_MAP_MESSAGE {
            guard let getWorldMapCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            onGetWorldMap?({ success, errorString, worldMap in
                var responseDictionary = [AnyHashable : Any]()
                responseDictionary["saved"] = success
                if errorString != nil {
                    responseDictionary["error"] = errorString ?? ""
                }
                if worldMap != nil {
                    if let aMap = worldMap {
                        responseDictionary["worldMap"] = aMap
                    }
                }
                blockSelf?.callWebMethod(getWorldMapCallback, paramJSON: responseDictionary, webCompletion: nil)
            })
        } else if message.name == WEB_AR_SET_WORLD_MAP_MESSAGE {
            let worldMapInfoDictionary = messageBody
            guard let setWorldMapCallback = messageBody[WEB_AR_CALLBACK_OPTION] as? String else { return }
            onSetWorldMap?(worldMapInfoDictionary, { success, errorString in
                var responseDictionary = [AnyHashable : Any]()
                responseDictionary["loaded"] = success
                if errorString != nil {
                    responseDictionary["error"] = errorString ?? ""
                }
                blockSelf?.callWebMethod(setWorldMapCallback, paramJSON: responseDictionary, webCompletion: nil)
            })
        } else {
            log.error("Unknown message: \(message.body) ,for name: \(message.name)")
        }

    }

    func callWebMethod(_ name: String, param: String?, webCompletion completion: WebCompletion?) {
        let jsonData = param != nil ? try? JSONSerialization.data(withJSONObject: [param], options: []) : Data()
        callWebMethod(name, jsonData: jsonData, webCompletion: completion)
    }

    func callWebMethod(_ name: String, paramJSON: Any?, webCompletion completion: WebCompletion?) {
        var jsonData: Data? = nil
        if let aJSON = paramJSON {
            jsonData = try? JSONSerialization.data(withJSONObject: aJSON, options: [])
        }
        callWebMethod(name, jsonData: jsonData, webCompletion: completion)
    }

    func callWebMethod(_ name: String?, jsonData: Data?, webCompletion completion: WebCompletion?) {
        assert(name != nil, " Web Massage name is nil !")

        var jsString: String? = nil
        if let aData = jsonData {
            jsString = String(data: aData, encoding: .utf8)
        }
        let jsScript = "\(name ?? "")(\(jsString ?? ""))"

        webView?.evaluateJavaScript(jsScript, completionHandler: completion)
    }

    // MARK: WKUIDelegate, WKNavigationDelegate

//    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        if let navigation = navigation {
//            log.debug("didStartProvisionalNavigation - \(navigation.debugDescription)\n on thread \(Thread.current.description)")
//        }
//
//        self.webView?.addObserver(self as NSObject, forKeyPath: "estimatedProgress", options: .new, context: nil)
//        documentReadyState = ""
//
//        onStartLoad?()
//
//        barView?.startLoading(self.webView?.url?.absoluteString)
//        barView?.setBackEnabled(self.webView?.canGoBack ?? false)
//        barView?.setForwardEnabled(self.webView?.canGoForward ?? false)
//    }
//
//    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        log.debug("didFinishNavigation - \(navigation.debugDescription)")
//        //    NSString* loadedURL = [[[self webView] URL] absoluteString];
//        //    [self setLastURL:loadedURL];
//        //
//        //    [[NSUserDefaults standardUserDefaults] setObject:loadedURL forKey:LAST_URL_KEY];
//        //
//        //    [self onFinishLoad]();
//        //
//        //    [[self barView] finishLoading:[[[self webView] URL] absoluteString]];
//        //    [[self barView] setBackEnabled:[[self webView] canGoBack]];
//        //    [[self barView] setForwardEnabled:[[self webView] canGoForward]];
//    }
//
//    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        log.error("Web Error - \(error)")
//
//        if self.webView?.observationInfo != nil {
//            self.webView?.removeObserver(self, forKeyPath: "estimatedProgress")
//        } else {
//            print("No Observers Found on WebView in WebController didFailProvisionalNavigation Check")
//        }
//
//        if shouldShowError(error: error as NSError) {
//            onError?(error)
//        }
//
//        barView?.finishLoading(self.webView?.url?.absoluteString)
//        barView?.setBackEnabled(self.webView?.canGoBack ?? false)
//        barView?.setForwardEnabled(self.webView?.canGoForward ?? false)
//    }
//
//    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        log.error("Web Error - \(error)")
//
//        if self.webView?.observationInfo != nil {
//            self.webView?.removeObserver(self as NSObject, forKeyPath: "estimatedProgress")
//        } else {
//            print("No Observers Found on WebView in WebController didFail Check")
//        }
//
//        if shouldShowError(error: error as NSError) {
//            onError?(error)
//        }
//
//        barView?.finishLoading(self.webView?.url?.absoluteString)
//        barView?.setBackEnabled(self.webView?.canGoBack ?? false)
//        barView?.setForwardEnabled(self.webView?.canGoForward ?? false)
//    }

    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return false
    }

    // MARK: Private

    func goFullScreen() {
        webViewTopAnchorConstraint?.constant = 0.0
    }

    func shouldShowError(error: NSError) -> Bool {
        return error.code > 600 || error.code < 200
    }

    func layout() {
        webView?.layoutIfNeeded()

//        barView?.layoutIfNeeded()
    }

    func setupWebUI() {
        webView?.autoresizesSubviews = true

        webView?.allowsLinkPreview = false
        webView?.isOpaque = false
        webView?.backgroundColor = UIColor.clear
        webView?.isUserInteractionEnabled = true
        webView?.scrollView.bounces = false
        webView?.scrollView.bouncesZoom = false
    }

//    func setupBarView() {
//        let barView = Bundle.main.loadNibNamed("XRBarView", owner: self, options: nil)?.first as? BarView
//        barView?.translatesAutoresizingMaskIntoConstraints = false
//        if let aView = barView {
//            webView?.superview?.addSubview(aView)
//        }
//
//        guard let barTopAnchor = barView?.superview?.topAnchor else { return }
//        guard let barRightAnchor = barView?.superview?.rightAnchor else { return }
//        guard let barLeftAnchor = barView?.superview?.leftAnchor else { return }
//        let topAnchorConstraint: NSLayoutConstraint? = barView?.topAnchor.constraint(equalTo: barTopAnchor)
//        topAnchorConstraint?.isActive = true
//        self.barViewTopAnchorConstraint = topAnchorConstraint
//
//        barView?.leftAnchor.constraint(equalTo: barLeftAnchor).isActive = true
//        barView?.rightAnchor.constraint(equalTo: barRightAnchor).isActive = true
//        let barViewHeightAnchorConstraint: NSLayoutConstraint? = barView?.heightAnchor.constraint(equalToConstant: CGFloat(Constant.urlBarHeight()))
//        self.barViewHeightAnchorConstraint = barViewHeightAnchorConstraint
//        barViewHeightAnchorConstraint?.isActive = true
//
//        self.barView = barView
//
//        weak var blockSelf: WebController? = self
//        weak var blockBar: BarView? = barView
//
//        barView?.backActionBlock = { sender in
//            if blockSelf?.webView?.canGoBack ?? false {
//                blockSelf?.webView?.goBack()
//            } else {
//                blockBar?.setBackEnabled(false)
//            }
//        }
//
//        barView?.forwardActionBlock = { sender in
//            if blockSelf?.webView?.canGoForward ?? false {
//                blockSelf?.webView?.goForward()
//            } else {
//                blockBar?.setForwardEnabled(false)
//            }
//        }
//
//        barView?.homeActionBlock = { sender in
//            self.goHome()
//        }
//
//        barView?.cancelActionBlock = { sender in
//            blockSelf?.webView?.stopLoading()
//        }
//
//        barView?.reloadActionBlock = { sender in
//            blockSelf?.loadURL?(blockBar?.urlFieldText())
//        }
//
//        barView?.showPermissionsActionBlock = { sender in
//            blockSelf?.onShowPermissions?()
//        }
//
//        barView?.goActionBlock = { url in
//            blockSelf?.loadURL(url)
//        }
//
//        barView?.debugButtonToggledAction = { selected in
//            blockSelf?.onDebugButtonToggled?(selected)
//        }
//
//        barView?.settingsActionBlock = {
//            blockSelf?.onSettingsButtonTapped?()
//        }
//
//        barView?.restartTrackingActionBlock = {
//            blockSelf?.onResetTrackingButtonTapped?()
//        }
//
//        barView?.switchCameraActionBlock = {
//            blockSelf?.onSwitchCameraButtonTapped?()
//        }
//    }

    func setupWebContent() {
        contentController?.add(self, name: WEB_AR_INIT_MESSAGE)
        contentController?.add(self, name: WEB_AR_INJECT_POLYFILL)
        contentController?.add(self, name: WEB_AR_START_WATCH_MESSAGE)
        contentController?.add(self, name: WEB_AR_REQUEST_MESSAGE)
        contentController?.add(self, name: WEB_AR_STOP_WATCH_MESSAGE)
        contentController?.add(self, name: WEB_AR_ON_JS_UPDATE_MESSAGE)
        contentController?.add(self, name: WEB_AR_LOAD_URL_MESSAGE)
        contentController?.add(self, name: WEB_AR_SET_UI_MESSAGE)
        contentController?.add(self, name: WEB_AR_HIT_TEST_MESSAGE)
        contentController?.add(self, name: WEB_AR_ADD_ANCHOR_MESSAGE)
        contentController?.add(self, name: WEB_AR_REMOVE_ANCHORS_MESSAGE)
        contentController?.add(self, name: WEB_AR_ADD_IMAGE_ANCHOR_MESSAGE)
        contentController?.add(self, name: WEB_AR_TRACKED_IMAGES_MESSAGE)
        contentController?.add(self, name: WEB_AR_CREATE_IMAGE_ANCHOR_MESSAGE)
        contentController?.add(self, name: WEB_AR_ACTIVATE_DETECTION_IMAGE_MESSAGE)
        contentController?.add(self, name: WEB_AR_DEACTIVATE_DETECTION_IMAGE_MESSAGE)
        contentController?.add(self, name: WEB_AR_DESTROY_DETECTION_IMAGE_MESSAGE)
        contentController?.add(self, name: WEB_AR_REQUEST_CV_DATA_MESSAGE)
        contentController?.add(self, name: WEB_AR_START_SENDING_CV_DATA_MESSAGE)
        contentController?.add(self, name: WEB_AR_STOP_SENDING_CV_DATA_MESSAGE)
        contentController?.add(self, name: WEB_AR_GET_WORLD_MAP_MESSAGE)
        contentController?.add(self, name: WEB_AR_SET_WORLD_MAP_MESSAGE)
    }

    func cleanWebContent() {
        contentController?.removeScriptMessageHandler(forName: WEB_AR_INIT_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_INJECT_POLYFILL)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_START_WATCH_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_REQUEST_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_STOP_WATCH_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_ON_JS_UPDATE_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_LOAD_URL_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_SET_UI_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_HIT_TEST_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_ADD_ANCHOR_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_REQUEST_CV_DATA_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_START_SENDING_CV_DATA_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_STOP_SENDING_CV_DATA_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_REMOVE_ANCHORS_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_ADD_IMAGE_ANCHOR_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_TRACKED_IMAGES_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_CREATE_IMAGE_ANCHOR_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_ACTIVATE_DETECTION_IMAGE_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_DEACTIVATE_DETECTION_IMAGE_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_DESTROY_DETECTION_IMAGE_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_GET_WORLD_MAP_MESSAGE)
        contentController?.removeScriptMessageHandler(forName: WEB_AR_SET_WORLD_MAP_MESSAGE)
    }

    func appVersion() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    
    func build() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String
    }
    
    func versionBuild() -> String? {
        let version = appVersion()
        let build = self.build()
        
        var versionBuild = "v\(version ?? "")"
        
        if version != build {
            versionBuild = "\(versionBuild)(\(build ?? ""))"
        }
        
        return versionBuild
    }

    func setupWebView(withRootView rootView: UIView?) {
        let conf = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        let version = versionBuild() ?? "unknown"
        conf.applicationNameForUserAgent = " Mobile WebXRViewer/" + version

        conf.userContentController = contentController
        self.contentController = contentController

        let pref = WKPreferences()
        pref.javaScriptEnabled = true
        conf.preferences = pref

        conf.processPool = WKProcessPool()

        conf.allowsInlineMediaPlayback = true
        conf.allowsAirPlayForMediaPlayback = true
        conf.allowsPictureInPictureMediaPlayback = true
        conf.mediaTypesRequiringUserActionForPlayback = []

        let wv = TabWebView(frame: rootView?.bounds ?? CGRect.zero, configuration: conf)
        rootView?.addSubview(wv)
        wv.translatesAutoresizingMaskIntoConstraints = false

        guard let rootTopAnchor = rootView?.topAnchor else { return }
        guard let rootBottomAnchor = rootView?.bottomAnchor else { return }
        guard let rootLeftAnchor = rootView?.leftAnchor else { return }
        guard let rootRightAnchor = rootView?.rightAnchor else { return }

        let webViewTopAnchorConstraint: NSLayoutConstraint = wv.topAnchor.constraint(equalTo: rootTopAnchor)
        self.webViewTopAnchorConstraint = webViewTopAnchorConstraint
        webViewTopAnchorConstraint.isActive = true
        let webViewLeftAnchorConstraint: NSLayoutConstraint = wv.leftAnchor.constraint(equalTo: rootLeftAnchor)
        self.webViewLeftAnchorConstraint = webViewLeftAnchorConstraint
        webViewLeftAnchorConstraint.isActive = true
        let webViewRightAnchorConstraint: NSLayoutConstraint = wv.rightAnchor.constraint(equalTo: rootRightAnchor)
        self.webViewRightAnchorConstraint = webViewRightAnchorConstraint
        webViewRightAnchorConstraint.isActive = true

        wv.bottomAnchor.constraint(equalTo: rootBottomAnchor).isActive = true

        wv.scrollView.contentInsetAdjustmentBehavior = .never

//        wv.navigationDelegate = self
//        wv.uiDelegate = self
        webView = wv
    }

    func documentDidBecomeInteractive() {
        print("documentDidBecomeInteractive")
        let loadedURL = webView?.url?.absoluteString

        lastURL = loadedURL ?? ""
        UserDefaults.standard.set(loadedURL, forKey: LAST_URL_KEY)

        onFinishLoad?()

//        barView?.finishLoading(webView?.url?.absoluteString)
//        barView?.setBackEnabled(webView?.canGoBack ?? false)
//        barView?.setForwardEnabled(webView?.canGoForward ?? false)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        weak var blockSelf: WebController? = self

        if (keyPath == "estimatedProgress") && (object as? WKWebView) == blockSelf?.webView {
            blockSelf?.webView?.evaluateJavaScript("document.readyState", completionHandler: { readyState, error in
                DispatchQueue.main.async(execute: {
                    print("Estimated progress: \(blockSelf?.webView?.estimatedProgress ?? 0.0)")
                    print("document.readyState: \(readyState ?? "")")

                    if ((readyState as? String == "interactive") && !(blockSelf?.documentReadyState == "interactive")) || ((blockSelf?.webView?.estimatedProgress ?? 0.0) >= 1.0) {
                        if blockSelf?.webView?.observationInfo != nil {
                            if let aSelf = blockSelf {
                                blockSelf?.webView?.removeObserver(aSelf as NSObject, forKeyPath: "estimatedProgress")
                            }
                            blockSelf?.documentDidBecomeInteractive()
                        } else {
                            print("No Observers Found on WebView in WebController Override observeValue Check")
                        }
                    }

                    blockSelf?.documentReadyState = readyState as? String ?? ""
                })
            })
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

@inline(__always) private func debugCompletion(name: String) -> WebCompletion {
    return { param, error in
        if error == nil {
            log.debug("\(name) : success")
        } else {
            log.debug("\(name) : error")
        }
    }
}
