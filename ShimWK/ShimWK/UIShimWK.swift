/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private var AssociatedObjectKeyWebView: UInt8 = 0

class UIShimWKFactory: ShimWKFactory {
    func wrapWKWebView(wrapper: ShimWKWebView, frame: CGRect, configuration: ShimWKWebViewConfiguration) -> ShimWKWebViewImpl {
        let webView = UIWebView(frame: frame)
        return UIShimWKWebView(wrapper: wrapper, configuration: configuration, webView: webView)
    }

    func wrapWKWebView(wrapper: ShimWKWebView, configuration: ShimWKWebViewConfiguration, makeInnerWKWebView: (() -> UIWebView)?) -> ShimWKWebViewImpl {
        guard let webView = makeInnerWKWebView?() else {
            let webView = UIWebView(frame: CGRectZero)
            return UIShimWKWebView(wrapper: wrapper, configuration: configuration, webView: webView)
        }

        return UIShimWKWebView(wrapper: wrapper, configuration: configuration, webView: webView)
    }

    func wrapWKProcessPool() -> ShimWKProcessPoolImpl {
        return UIShimWKProcessPool()
    }

    func wrapWKWebViewConfiguration(wrapper: ShimWKWebViewConfiguration) -> ShimWKWebViewConfigurationImpl {
        let configuration = UIShimWKWebViewConfiguration()
//        configuration.setWrapper(wrapper)
        return configuration
    }

    func wrapWKUserContentController(wrapper: ShimWKUserContentController) -> ShimWKUserContentControllerImpl {
        let controller = UIShimWKUserContentController()
//        controller.setWrapper(wrapper)
        return controller
    }

    func wrapWKUserScript(source: String, injectionTime: ShimWKUserScriptInjectionTime, forMainFrameOnly: Bool) -> ShimWKUserScriptImpl {
        return WKShimWKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: forMainFrameOnly)
    }

    func wrapWKWebsiteDataStore(persistent persistent: Bool) -> ShimWKWebsiteDataStoreImpl {
        return UIShimWKWebsiteDataStore()
    }

    func wrapWKPreferences() -> ShimWKPreferencesImpl {
        return UIShimWKPreferences()
    }
}

private class UIShimWKWebView: NSObject, ShimWKWebViewImpl, UIWebViewDelegate {
    let configuration: ShimWKWebViewConfiguration
    let webView: UIWebView

    private weak var wrapper: ShimWKWebView?

    init(wrapper: ShimWKWebView, configuration: ShimWKWebViewConfiguration, webView: UIWebView) {
        self.configuration = configuration
        self.wrapper = wrapper
        self.webView = webView

        super.init()

        webView.delegate = self

        // Weakly associate this wrapper with the UIWebView. This lets us easily get a reference
        // to the wrapper later, which we'll need for any delegate callbacks.
        assert(getWrapperFromWebView(webView) == nil)
        objc_setAssociatedObject(webView, &AssociatedObjectKeyWebView, wrapper, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
    }

    weak var navigationDelegate: ShimWKNavigationDelegate? = nil {
        didSet {

        }
    }

    weak var UIDelegate: ShimWKUIDelegate? = nil {
        didSet {

        }
    }

    let backForwardList: ShimWKBackForwardList = UIShimWKBackForwardList()

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

        }
    }

    var customUserAgent: String? = nil {
        didSet {

        }
    }

    func evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> ())?) {

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
        return ShimWKNavigation()
    }

    func stopLoading() {
        webView.stopLoading()
    }

    func goToBackForwardListItem(item: ShimWKBackForwardListItem) -> ShimWKNavigation? {
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

    }

    @objc private func webViewDidStartLoad(webView: UIWebView) {
        wrapper?.loading = true
    }

    @objc private func webViewDidFinishLoad(webView: UIWebView) {
        guard let wrapper = wrapper else { return }

        wrapper.canGoBack = webView.canGoBack
        wrapper.canGoForward = webView.canGoForward
        wrapper.loading = false
        wrapper.title = webView.stringByEvaluatingJavaScriptFromString("document.title")

        let href = webView.stringByEvaluatingJavaScriptFromString("document.location.href")
        if let href = href {
            wrapper.URL = NSURL(string: href)
        } else {
            wrapper.URL = nil
        }

        navigationDelegate?.webView?(wrapper, didCommitNavigation: ShimWKNavigation())
    }

    @objc private func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        guard let wrapper = wrapper else { return }

        navigationDelegate?.webView?(wrapper, didFailProvisionalNavigation: ShimWKNavigation(), withError: error)
    }
}

private func getWrapperFromWebView(webView: UIWebView) -> ShimWKWebView? {
    return objc_getAssociatedObject(webView, &AssociatedObjectKeyWebView) as? ShimWKWebView
}

private class UIShimWKWebViewConfiguration: ShimWKWebViewConfigurationImpl {
    init() {

    }

    // Ignored.
    @objc var processPool: ShimWKProcessPool = ShimWKProcessPool()

    @objc var preferences: ShimWKPreferences = ShimWKPreferences() {
        didSet {

        }
    }

    @objc var userContentController: ShimWKUserContentController = ShimWKUserContentController() {
        didSet {

        }
    }

    @objc var websiteDataStore: ShimWKWebsiteDataStore = ShimWKWebsiteDataStore.defaultDataStore() {
        didSet {

        }
    }

    @objc var applicationNameForUserAgent: String? = nil {
        didSet {

        }
    }
}

// Unused.
private class UIShimWKProcessPool: NSObject, ShimWKProcessPoolImpl {

}

private class UIShimWKNavigationAction: NSObject, ShimWKNavigationAction {
    @objc let sourceFrame: ShimWKFrameInfo
    @objc let targetFrame: ShimWKFrameInfo?
    @objc let navigationType: ShimWKNavigationType
    @objc let request: NSURLRequest

    init(sourceFrame: ShimWKFrameInfo, targetFrame: ShimWKFrameInfo?, navigationType: ShimWKNavigationType, request: NSURLRequest) {
        self.sourceFrame = sourceFrame
        self.targetFrame = targetFrame
        self.navigationType = navigationType
        self.request = request
    }
}

private class UIShimWKNavigationResponse: NSObject, ShimWKNavigationResponse {
    @objc let isForMainFrame: Bool
    @objc let response: NSURLResponse
    @objc let canShowMIMEType: Bool

    init(isForMainFrame: Bool, response: NSURLResponse, canShowMIMEType: Bool) {
        self.isForMainFrame = isForMainFrame
        self.response = response
        self.canShowMIMEType = canShowMIMEType
    }
}

private class UIShimWKFrameInfo: NSObject, ShimWKFrameInfo {
    @objc let mainFrame: Bool
    @objc let request: NSURLRequest
    @objc let securityOrigin: ShimWKSecurityOrigin

    init(mainFrame: Bool, request: NSURLRequest, securityOrigin: ShimWKSecurityOrigin) {
        self.mainFrame = mainFrame
        self.request = request
        self.securityOrigin = securityOrigin
    }
}

private class UIShimWKScriptMessage: ShimWKScriptMessage {
    let webView: ShimWKWebView?
    let body: AnyObject
    let frameInfo: ShimWKFrameInfo
    let name: String

    init(webView: ShimWKWebView?, body: AnyObject, frameInfo: ShimWKFrameInfo, name: String) {
        self.body = body
        self.webView = webView
        self.frameInfo = frameInfo
        self.name = name
    }
}

private class UIShimWKPreferences: NSObject, ShimWKPreferencesImpl {
    override init() {
    }

    // WKTODO: Does updating WKPreferences live update the web view?
    var javaScriptCanOpenWindowsAutomatically: Bool = false
}

class UIShimWKUserScript: ShimWKUserScriptImpl {
    let source: String
    let injectionTime: ShimWKUserScriptInjectionTime
    let isForMainFrameOnly: Bool

    required init(source: String, injectionTime: ShimWKUserScriptInjectionTime, forMainFrameOnly: Bool) {
        self.source = source
        self.injectionTime = injectionTime
        self.isForMainFrameOnly = forMainFrameOnly
    }
}

private class UIShimWKUserContentController: ShimWKUserContentControllerImpl {
    private(set) var userScripts = [ShimWKUserScript]()

    func addUserScript(userScript: ShimWKUserScript) {
        userScripts.append(userScript)
    }

    func removeAllUserScripts() {
        userScripts.removeAll()
    }

    func addScriptMessageHandler(handler: ShimWKScriptMessageHandler, name: String) {
    }

    func removeScriptMessageHandler(forName name: String) {
    }
}

private class UIShimWKBackForwardList: ShimWKBackForwardList {
    init() {
    }

    var currentItem: ShimWKBackForwardListItem? {
        return nil
    }

    var backItem: ShimWKBackForwardListItem? {
        return nil
    }

    var forwardItem: ShimWKBackForwardListItem? {
        return nil
    }

    var backList: [ShimWKBackForwardListItem] {
        return []
    }

    var forwardList: [ShimWKBackForwardListItem] {
        return []
    }

    func itemAtIndex(index: Int) -> ShimWKBackForwardListItem? {
        return nil
    }
}

private class UIShimWKWebsiteDataStore: NSObject, ShimWKWebsiteDataStoreImpl {
    func removeDataOfTypes(websiteDataTypes: Set<String>, modifiedSince date: NSDate, completionHandler: () -> ()) {

    }
}
