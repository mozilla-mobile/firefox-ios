/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

private var AssociatedObjectKeyWebView: UInt8 = 0
private var AssociatedObjectKeyUserContentController: UInt8 = 0
private var AssociatedObjectKeyConfiguration: UInt8 = 0
private var AssociatedObjectKeyNavigationDelegate: UInt8 = 0
private var AssociatedObjectKeyUIDelegate: UInt8 = 0

extension WKProcessPool: ShimWKProcessPoolImpl {}
extension WKBackForwardListItem: ShimWKBackForwardListItem {}
extension WKSecurityOrigin: ShimWKSecurityOrigin {}
extension WKWebsiteDataRecord: ShimWKWebsiteDataRecord {}
extension WKWindowFeatures: ShimWKWindowFeatures {}

class WKShimWKFactory: ShimWKFactory {
    func wrapWKWebView(wrapper: ShimWKWebView, frame: CGRect, configuration: ShimWKWebViewConfiguration) -> ShimWKWebViewImpl {
        let wkConfig = (configuration._impl as! WKShimWKWebViewConfiguration).configuration
        let webView = WKWebView(frame: frame, configuration: wkConfig)
        return WKShimWKWebView(wrapper: wrapper, configuration: configuration, webView: webView)
    }

    func wrapWKWebView(wrapper: ShimWKWebView, configuration: ShimWKWebViewConfiguration, makeInnerWKWebView: (WKWebViewConfiguration -> WKWebView)?) -> ShimWKWebViewImpl {
        let wkConfig = (configuration._impl as! WKShimWKWebViewConfiguration).configuration

        guard let webView = makeInnerWKWebView?(wkConfig) else {
            let webView = WKWebView(frame: CGRectZero, configuration: wkConfig)
            return WKShimWKWebView(wrapper: wrapper, configuration: configuration, webView: webView)
        }

        return WKShimWKWebView(wrapper: wrapper, configuration: configuration, webView: webView)
    }

    func wrapWKProcessPool() -> ShimWKProcessPoolImpl {
        return WKProcessPool()
    }

    func wrapWKWebViewConfiguration(wrapper: ShimWKWebViewConfiguration) -> ShimWKWebViewConfigurationImpl {
        let configuration = WKShimWKWebViewConfiguration(configuration: WKWebViewConfiguration())
        configuration.setWrapper(wrapper)
        return configuration
    }

    func wrapWKUserContentController(wrapper: ShimWKUserContentController) -> ShimWKUserContentControllerImpl {
        let controller = WKShimWKUserContentController(controller: WKUserContentController())
        controller.setWrapper(wrapper)
        return controller
    }

    func wrapWKUserScript(source: String, injectionTime: ShimWKUserScriptInjectionTime, forMainFrameOnly: Bool) -> ShimWKUserScriptImpl {
        return WKShimWKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
    }

    func wrapWKWebsiteDataStore(persistent persistent: Bool) -> ShimWKWebsiteDataStoreImpl {
        if persistent {
            return WKShimWKWebsiteDataStore(store: WKWebsiteDataStore.defaultDataStore())
        }

        return WKShimWKWebsiteDataStore(store: WKWebsiteDataStore.nonPersistentDataStore())
    }

    func wrapWKPreferences() -> ShimWKPreferencesImpl {
        return WKShimWKPreferences(preferences: WKPreferences())
    }
}

private let KVOURL = "URL"
private let KVOTitle = "title"
private let KVOLoading = "loading"
private let KVOCanGoBack = "canGoBack"
private let KVOCanGoForward = "canGoForward"
private let KVOEstimatedProgress = "estimatedProgress"

private class WKShimWKWebView: NSObject, ShimWKWebViewImpl {
    let configuration: ShimWKWebViewConfiguration
    let webView: WKWebView

    private weak var wrapper: ShimWKWebView?

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard let path = keyPath else { return }

        switch path {
        case KVOURL: wrapper?.URL = change![NSKeyValueChangeNewKey] as? NSURL
        case KVOTitle: wrapper?.title = change![NSKeyValueChangeNewKey] as? String
        case KVOLoading: wrapper?.loading = change![NSKeyValueChangeNewKey] as! Bool
        case KVOCanGoBack: wrapper?.canGoBack = change![NSKeyValueChangeNewKey] as! Bool
        case KVOCanGoForward: wrapper?.canGoForward = change![NSKeyValueChangeNewKey] as! Bool
        case KVOEstimatedProgress: wrapper?.estimatedProgress = change![NSKeyValueChangeNewKey] as! Double
        default: break
        }
    }

    init(wrapper: ShimWKWebView, configuration: ShimWKWebViewConfiguration, webView: WKWebView) {
        self.configuration = configuration
        self.wrapper = wrapper
        self.webView = webView

        super.init()

        // Use KVO to keep the web view's properties in sync with the shim.
        webView.addObserver(self, forKeyPath: KVOURL, options: .New, context: nil)
        webView.addObserver(self, forKeyPath: KVOTitle, options: .New, context: nil)
        webView.addObserver(self, forKeyPath: KVOLoading, options: .New, context: nil)
        webView.addObserver(self, forKeyPath: KVOCanGoBack, options: .New, context: nil)
        webView.addObserver(self, forKeyPath: KVOCanGoForward, options: .New, context: nil)
        webView.addObserver(self, forKeyPath: KVOEstimatedProgress, options: .New, context: nil)

        // Weakly associate this wrapper with the WKWebView. This lets us easily get a reference
        // to the wrapper later, which we'll need for any delegate callbacks.
        assert(getWrapperFromWebView(webView) == nil)
        objc_setAssociatedObject(webView, &AssociatedObjectKeyWebView, wrapper, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
    }

    weak var navigationDelegate: ShimWKNavigationDelegate? = nil {
        didSet {
            guard let delegate = navigationDelegate else {
                webView.navigationDelegate = nil
                return
            }

            if let wrappedDelegate = objc_getAssociatedObject(delegate, &AssociatedObjectKeyNavigationDelegate) as?  WKNavigationDelegateWrapper {
                webView.navigationDelegate = wrappedDelegate
                return
            }

            let wrappedDelegate = WKNavigationDelegateWrapper(delegate: delegate)
            webView.navigationDelegate = wrappedDelegate

            // Strongly associate the delegate with the wrapped delegate to prevent the wrapped
            // delegate from going out of scope (since it is weakly held by the web view). We don't
            // actually need to access this later; we're simply storing the reference to tie the
            // object lifecycles together.
            assert(objc_getAssociatedObject(delegate, &AssociatedObjectKeyNavigationDelegate) == nil)
            objc_setAssociatedObject(delegate, &AssociatedObjectKeyNavigationDelegate, wrappedDelegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    weak var UIDelegate: ShimWKUIDelegate? = nil {
        didSet {
            guard let delegate = UIDelegate else {
                webView.UIDelegate = nil
                return
            }

            if let wrappedDelegate = objc_getAssociatedObject(delegate, &AssociatedObjectKeyUIDelegate) as? WKUIDelegateWrapper {
                webView.UIDelegate = wrappedDelegate
                return
            }

            let wrappedDelegate = WKUIDelegateWrapper(delegate: delegate)
            webView.UIDelegate = wrappedDelegate

            // Strongly associate the delegate with the wrapped delegate to prevent the wrapped
            // delegate from going out of scope (since it is weakly held by the web view). We don't
            // actually need to access this later; we're simply storing the reference to tie the
            // object lifecycles together.
            assert(objc_getAssociatedObject(delegate, &AssociatedObjectKeyUIDelegate) == nil)
            objc_setAssociatedObject(delegate, &AssociatedObjectKeyUIDelegate, wrappedDelegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var backForwardList: ShimWKBackForwardList {
        return WKShimWKBackForwardList(list: webView.backForwardList)
    }

    var allowsLinkPreview: Bool = false {
        didSet {
            webView.allowsLinkPreview = allowsLinkPreview
        }
    }

    var view: UIView {
        return webView
    }

    var scrollView: UIScrollView {
        return webView.scrollView
    }

    var allowsBackForwardNavigationGestures: Bool = false {
        didSet {
            webView.allowsBackForwardNavigationGestures = allowsBackForwardNavigationGestures
        }
    }

    var customUserAgent: String? = nil {
        didSet {
            webView.customUserAgent = customUserAgent
        }
    }

    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> ())?) {
        webView.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }

    func loadRequest(request: NSURLRequest) -> ShimWKNavigation? {
        webView.loadRequest(request)
        return ShimWKNavigation()
    }

    func reload() -> ShimWKNavigation? {
        webView.reload()
        return ShimWKNavigation()
    }

    func reloadFromOrigin() -> ShimWKNavigation? {
        webView.reloadFromOrigin()
        return ShimWKNavigation()
    }

    func stopLoading() {
        webView.stopLoading()
    }

    func goToBackForwardListItem(item: ShimWKBackForwardListItem) -> ShimWKNavigation? {
        webView.goToBackForwardListItem(item as! WKBackForwardListItem)
        return ShimWKNavigation()
    }

    func goBack() -> ShimWKNavigation? {
        webView.goBack()
        return ShimWKNavigation()
    }

    func goForward() -> ShimWKNavigation? {
        webView.goForward()
        return ShimWKNavigation()
    }

    deinit {
        webView.removeObserver(self, forKeyPath: KVOURL)
        webView.removeObserver(self, forKeyPath: KVOTitle)
        webView.removeObserver(self, forKeyPath: KVOLoading)
        webView.removeObserver(self, forKeyPath: KVOCanGoBack)
        webView.removeObserver(self, forKeyPath: KVOCanGoForward)
        webView.removeObserver(self, forKeyPath: KVOEstimatedProgress)
    }
}

private func getWrapperFromWebView(webView: WKWebView) -> ShimWKWebView? {
    return objc_getAssociatedObject(webView, &AssociatedObjectKeyWebView) as? ShimWKWebView
}

private class WKUIDelegateWrapper: NSObject, WKUIDelegate {
    weak var delegate: ShimWKUIDelegate?

    init(delegate: ShimWKUIDelegate) {
        self.delegate = delegate
    }

    @objc private func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard let webView = getWrapperFromWebView(webView) else { return nil }

        let navigationAction = WKShimWKNavigationAction(action: navigationAction)

        var wrapConfiguration: ShimWKWebViewConfiguration! = objc_getAssociatedObject(configuration, &AssociatedObjectKeyConfiguration) as? ShimWKWebViewConfiguration

        if wrapConfiguration == nil {
            let configurationImpl = WKShimWKWebViewConfiguration(configuration: configuration)
            wrapConfiguration = ShimWKWebViewConfiguration(impl: configurationImpl)
            configurationImpl.setWrapper(wrapConfiguration)
        }

        let wrappedWebView = delegate?.webView?(webView, createWebViewWithConfiguration: wrapConfiguration, forNavigationAction: navigationAction, windowFeatures: windowFeatures)
        return (wrappedWebView?._impl as? WKShimWKWebView)?.webView
    }

    @objc private func webView(webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: () -> Void) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        let frame = WKShimWKFrameInfo(info: frame)
        delegate?.webView?(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }

    @objc private func webView(webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (Bool) -> Void) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        let frame = WKShimWKFrameInfo(info: frame)
        delegate?.webView?(webView, runJavaScriptConfirmPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }

    @objc private func webView(webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: (String?) -> Void) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        let frame = WKShimWKFrameInfo(info: frame)
        delegate?.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler)
    }
}

private class WKNavigationDelegateWrapper: NSObject, WKNavigationDelegate {
    weak var delegate: ShimWKNavigationDelegate?

    init(delegate: ShimWKNavigationDelegate) {
        self.delegate = delegate
    }

    @objc private func webViewWebContentProcessDidTerminate(webView: WKWebView) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webViewWebContentProcessDidTerminate?(webView)
    }

    @objc private func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webView?(webView, didCommitNavigation: ShimWKNavigation())
    }

    @objc private func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webView?(webView, didFinishNavigation: ShimWKNavigation())
    }

    @objc private func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webView?(webView, didStartProvisionalNavigation: ShimWKNavigation())
    }

    @objc private func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webView?(webView, didFailNavigation: ShimWKNavigation(), withError: error)
    }

    @objc private func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: ShimWKNavigation())
    }

    @objc private func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webView?(webView, didFailProvisionalNavigation: ShimWKNavigation(), withError: error)
    }

    @objc private func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webView?(webView, decidePolicyForNavigationAction: WKShimWKNavigationAction(action: navigationAction)) { policy in
            decisionHandler(policy)
        }
    }

    @objc private func webView(webView: WKWebView, decidePolicyForNavigationResponse navigationResponse: WKNavigationResponse, decisionHandler: (WKNavigationResponsePolicy) -> Void) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webView?(webView, decidePolicyForNavigationResponse: WKShimWKNavigationResponse(response: navigationResponse)) { policy in
            decisionHandler(policy)
        }
    }

    @objc private func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        guard let webView = getWrapperFromWebView(webView) else { return }
        delegate?.webView?(webView, didReceiveAuthenticationChallenge: challenge, completionHandler: completionHandler)
    }
}

private class WKShimWKWebViewConfiguration: ShimWKWebViewConfigurationImpl {
    private let configuration: WKWebViewConfiguration

    init(configuration: WKWebViewConfiguration) {
        self.configuration = configuration

        // A new WKWebViewConfiguration will already have an instance of a process pool,
        // preferences, etc. Wrap these existing objects.
        processPool = ShimWKProcessPool(impl: configuration.processPool)
        preferences = ShimWKPreferences(impl: WKShimWKPreferences(preferences: configuration.preferences))
        websiteDataStore = ShimWKWebsiteDataStore(impl: WKShimWKWebsiteDataStore(store: configuration.websiteDataStore))
        applicationNameForUserAgent = configuration.applicationNameForUserAgent

        guard let wrapController = objc_getAssociatedObject(configuration.userContentController, &AssociatedObjectKeyUserContentController) as? ShimWKUserContentController else {
            let controllerImpl = WKShimWKUserContentController(controller: configuration.userContentController)
            userContentController = ShimWKUserContentController(impl: controllerImpl)
            controllerImpl.setWrapper(userContentController)
            return
        }

        userContentController = wrapController
    }

    private func setWrapper(wrapper: ShimWKWebViewConfiguration) {
        assert(objc_getAssociatedObject(configuration, &AssociatedObjectKeyConfiguration) == nil)
        objc_setAssociatedObject(configuration, &AssociatedObjectKeyConfiguration, wrapper,
                                 objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
    }

    @objc var processPool: ShimWKProcessPool {
        didSet {
            configuration.processPool = processPool._impl as! WKProcessPool
        }
    }

    @objc var preferences: ShimWKPreferences {
        didSet {
            configuration.preferences = (preferences._impl as! WKShimWKPreferences).preferences
        }
    }

    @objc var userContentController: ShimWKUserContentController {
        didSet {
            configuration.userContentController = (userContentController._impl as! WKShimWKUserContentController).controller
        }
    }

    @objc var websiteDataStore: ShimWKWebsiteDataStore {
        didSet {
            configuration.websiteDataStore = (websiteDataStore._impl as! WKShimWKWebsiteDataStore).store
        }
    }

    @objc var applicationNameForUserAgent: String? {
        didSet {
            configuration.applicationNameForUserAgent = applicationNameForUserAgent
        }
    }
}

private class WKShimWKNavigationAction: NSObject, ShimWKNavigationAction {
    private let action: WKNavigationAction

    init(action: WKNavigationAction) {
        self.action = action
    }

    @objc var sourceFrame: ShimWKFrameInfo {
        return WKShimWKFrameInfo(info: action.sourceFrame)
    }

    @objc var targetFrame: ShimWKFrameInfo? {
        guard let info = action.targetFrame else { return nil }
        return WKShimWKFrameInfo(info: info)
    }

    @objc var navigationType: ShimWKNavigationType {
        return action.navigationType
    }

    @objc var request: NSURLRequest {
        return action.request
    }
}

private class WKShimWKNavigationResponse: NSObject, ShimWKNavigationResponse {
    private let navigationResponse: WKNavigationResponse

    init(response: WKNavigationResponse) {
        self.navigationResponse = response
    }

    @objc var isForMainFrame: Bool {
        return navigationResponse.forMainFrame
    }

    @objc var response: NSURLResponse {
        return navigationResponse.response
    }

    @objc var canShowMIMEType: Bool {
        return navigationResponse.canShowMIMEType
    }
}

private class WKShimWKFrameInfo: NSObject, ShimWKFrameInfo {
    let info: WKFrameInfo

    init(info: WKFrameInfo) {
        self.info = info
    }

    @objc var mainFrame: Bool {
        return info.mainFrame
    }

    @objc var request: NSURLRequest {
        return info.request
    }

    @objc var securityOrigin: ShimWKSecurityOrigin {
        return info.securityOrigin
    }
}

private class WKShimWKScriptMessage: ShimWKScriptMessage {
    let message: WKScriptMessage

    init(message: WKScriptMessage) {
        self.message = message
    }

    var body: AnyObject {
        return message.body
    }

    var webView: ShimWKWebView? {
        guard let webView = message.webView else { return nil }
        return getWrapperFromWebView(webView)
    }

    var frameInfo: ShimWKFrameInfo {
        return WKShimWKFrameInfo(info: message.frameInfo)
    }

    var name: String {
        return message.name
    }
}

private class WKShimWKPreferences: NSObject, ShimWKPreferencesImpl {
    private let preferences: WKPreferences

    init(preferences: WKPreferences) {
        self.preferences = preferences
    }

    var javaScriptCanOpenWindowsAutomatically: Bool = false {
        didSet {
            preferences.javaScriptCanOpenWindowsAutomatically = javaScriptCanOpenWindowsAutomatically
        }
    }
}

class WKShimWKUserScript: ShimWKUserScriptImpl {
    private let userScript: WKUserScript

    required init(source: String, injectionTime: ShimWKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        userScript = WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
    }

    var source: String {
        return userScript.source
    }

    var injectionTime: ShimWKUserScriptInjectionTime {
        return userScript.injectionTime
    }

    var isForMainFrameOnly: Bool {
        return userScript.forMainFrameOnly
    }
}

private class WKShimWKUserContentController: ShimWKUserContentControllerImpl {
    private let controller: WKUserContentController

    init(controller: WKUserContentController) {
        self.controller = controller
    }

    private func setWrapper(wrapper: ShimWKUserContentController) {
        assert(objc_getAssociatedObject(controller, &AssociatedObjectKeyUserContentController) == nil)
        objc_setAssociatedObject(controller, &AssociatedObjectKeyUserContentController, wrapper, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
    }

    private(set) var userScripts = [ShimWKUserScript]()

    func addUserScript(userScript: ShimWKUserScript) {
        controller.addUserScript((userScript._impl as! WKShimWKUserScript).userScript)
        userScripts.append(userScript)
    }

    func removeAllUserScripts() {
        controller.removeAllUserScripts()
        userScripts.removeAll()
    }

    func addScriptMessageHandler(handler: ShimWKScriptMessageHandler, name: String) {
        let handler = WKScriptMessageHandlerWrapper(handler: handler)
        controller.addScriptMessageHandler(handler, name: name)
    }

    func removeScriptMessageHandler(forName name: String) {
        controller.removeScriptMessageHandlerForName(name)
    }
}

private class WKScriptMessageHandlerWrapper: NSObject, WKScriptMessageHandler {
    weak var handler: ShimWKScriptMessageHandler?

    init(handler: ShimWKScriptMessageHandler) {
        self.handler = handler
    }

    @objc func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let controller = objc_getAssociatedObject(userContentController, &AssociatedObjectKeyUserContentController) as? ShimWKUserContentController else { return }
        let message = WKShimWKScriptMessage(message: message)
        handler?.userContentController(controller, didReceiveScriptMessage: message)
    }
}


private class WKShimWKBackForwardList: ShimWKBackForwardList {
    let list: WKBackForwardList

    init(list: WKBackForwardList) {
        self.list = list
    }

    var currentItem: ShimWKBackForwardListItem? {
        return list.currentItem
    }

    var backItem: ShimWKBackForwardListItem? {
        return list.backItem
    }

    var forwardItem: ShimWKBackForwardListItem? {
        return list.forwardItem
    }

    var backList: [ShimWKBackForwardListItem] {
        return list.backList.map { $0 as ShimWKBackForwardListItem }
    }

    var forwardList: [ShimWKBackForwardListItem] {
        return list.forwardList.map { $0 as ShimWKBackForwardListItem }
    }

    func itemAtIndex(index: Int) -> ShimWKBackForwardListItem? {
        return list.itemAtIndex(index)
    }
}

private class WKShimWKWebsiteDataStore: NSObject, ShimWKWebsiteDataStoreImpl {
    private let store: WKWebsiteDataStore

    private init(store: WKWebsiteDataStore) {
        self.store = store
    }

    func removeDataOfTypes(websiteDataTypes: Set<String>, modifiedSince date: NSDate, completionHandler: () -> ()) {
        store.removeDataOfTypes(websiteDataTypes, modifiedSince: date, completionHandler: completionHandler)
    }
}
