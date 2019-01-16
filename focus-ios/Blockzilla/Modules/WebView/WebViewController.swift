/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit
import Telemetry
import OnePasswordExtension

protocol BrowserState {
    var url: URL? { get }
    var isLoading: Bool { get }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    var estimatedProgress: Double { get }
}

protocol WebController {
    var delegate: WebControllerDelegate? { get set }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }

    func load(_ request: URLRequest)
}

protocol WebControllerDelegate: class {
    func webControllerDidStartProvisionalNavigation(_ controller: WebController)
    func webControllerDidStartNavigation(_ controller: WebController)
    func webControllerDidFinishNavigation(_ controller: WebController)
    func webControllerDidNavigateBack(_ controller: WebController)
    func webControllerDidNavigateForward(_ controller: WebController)
    func webControllerDidReload(_ controller: WebController)
    func webControllerURLDidChange(_ controller: WebController, url: URL)
    func webController(_ controller: WebController, didFailNavigationWithError error: Error)
    func webController(_ controller: WebController, didUpdateCanGoBack canGoBack: Bool)
    func webController(_ controller: WebController, didUpdateCanGoForward canGoForward: Bool)
    func webController(_ controller: WebController, didUpdateEstimatedProgress estimatedProgress: Double)
    func webController(_ controller: WebController, scrollViewWillBeginDragging scrollView: UIScrollView)
    func webController(_ controller: WebController, scrollViewDidEndDragging scrollView: UIScrollView)
    func webController(_ controller: WebController, scrollViewDidScroll scrollView: UIScrollView)
    func webController(_ controller: WebController, stateDidChange state: BrowserState)
    func webControllerShouldScrollToTop(_ controller: WebController) -> Bool
    func webController(_ controller: WebController, didUpdateTrackingProtectionStatus trackingStatus: TrackingProtectionStatus)
    func webController(_ controller: WebController, didUpdateFindInPageResults currentResult: Int?, totalResults: Int?)
}

class WebViewController: UIViewController, WebController {
    private enum ScriptHandlers: String {
        case focusTrackingProtection
        case focusTrackingProtectionPostLoad
        case findInPageHandler

        static var allValues: [ScriptHandlers] { return [.focusTrackingProtection, .focusTrackingProtectionPostLoad, .findInPageHandler] }
    }

    private enum KVOConstants: String, CaseIterable {
        case URL = "URL"
        case canGoBack = "canGoBack"
        case canGoForward = "canGoForward"
    }

    weak var delegate: WebControllerDelegate?

    private var browserView: WKWebView!
    var onePasswordExtensionItem: NSExtensionItem!
    private var progressObserver: NSKeyValueObservation?
    private var urlObserver: NSKeyValueObservation?
    private var currentBackForwardItem: WKBackForwardListItem?
    private var userAgent: UserAgent?
    private var trackingProtectionStatus = TrackingProtectionStatus.on(TPPageStats()) {
        didSet {
            delegate?.webController(self, didUpdateTrackingProtectionStatus: trackingProtectionStatus)
        }
    }

    private var trackingInformation = TPPageStats() {
        didSet {
            if case .on = trackingProtectionStatus {
                trackingProtectionStatus = .on(trackingInformation)
            }
        }
    }

    var pageTitle: String? {
        return browserView.title
    }

    var userAgentString: String? {
        return self.userAgent?.getUserAgent()
    }

    var printFormatter: UIPrintFormatter { return browserView.viewPrintFormatter() }
    var scrollView: UIScrollView { return browserView.scrollView }

    convenience init(userAgent: UserAgent = UserAgent.shared) {
        self.init(nibName: nil, bundle: nil)

        self.userAgent = userAgent

        setupWebview()
        ContentBlockerHelper.shared.handler = reloadBlockers(_:)
    }

    func reset() {
        userAgent?.setup()
        browserView.load(URLRequest(url: URL(string: "about:blank")!))
        browserView.navigationDelegate = nil
        browserView.removeFromSuperview()
        trackingProtectionStatus = .on(TPPageStats())
        setupWebview()
        self.browserView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
    }

    // Browser proxy methods
    func load(_ request: URLRequest) { browserView.load(request) }
    func goBack() { browserView.goBack() }
    func goForward() { browserView.goForward() }
    func reload() { browserView.reload() }

    @available(iOS 9, *)
    func requestUserAgentChange() {
        guard let currentItem = browserView.backForwardList.currentItem else {
            return
        }

        userAgent?.changeUserAgent()
        browserView.customUserAgent = userAgent?.getUserAgent()

        if currentItem.url != currentItem.initialURL {
            // Reload the initial URL to avoid UA specific redirection
            browserView.load(URLRequest(url: currentItem.initialURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60))
        } else {
            reload() // Reload the current URL. We cannot use loadRequest in this case because it seems to leverage caching.
        }
        UserDefaults.standard.set(false, forKey: TipManager.TipKey.requestDesktopTip)
    }

    func resetUA() {
        browserView.customUserAgent = userAgent?.browserUserAgent
    }

    func stop() { browserView.stopLoading() }

    private func setupWebview() {
        let wvConfig = WKWebViewConfiguration()
        wvConfig.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        wvConfig.allowsInlineMediaPlayback = true
        browserView = WKWebView(frame: .zero, configuration: wvConfig)

        browserView.allowsBackForwardNavigationGestures = true
        browserView.allowsLinkPreview = false
        browserView.scrollView.clipsToBounds = false
        browserView.scrollView.delegate = self
        browserView.navigationDelegate = self
        browserView.uiDelegate = self

        progressObserver = browserView.observe(\WKWebView.estimatedProgress) { (webView, value) in
            self.delegate?.webController(self, didUpdateEstimatedProgress: webView.estimatedProgress)
        }

        setupBlockLists()
        setupTrackingProtectionScripts()
        setupFindInPageScripts()

        view.addSubview(browserView)
        browserView.snp.makeConstraints { make in
            make.edges.equalTo(view.snp.edges)
        }

        KVOConstants.allCases.forEach { browserView.addObserver(self, forKeyPath: $0.rawValue, options: .new, context: nil) }
    }

    @objc private func reloadBlockers(_ blockLists: [WKContentRuleList]) {
        DispatchQueue.main.async {
            self.browserView.configuration.userContentController.removeAllContentRuleLists()
            blockLists.forEach(self.browserView.configuration.userContentController.add)
        }
    }

    private func setupBlockLists() {
        ContentBlockerHelper.shared.getBlockLists { lists in
            self.reloadBlockers(lists)
        }
    }

    private func addScript(forResource resource: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly mainFrameOnly: Bool) {
        let source = try! String(contentsOf: Bundle.main.url(forResource: resource, withExtension: "js")!)
        let script = WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: mainFrameOnly)
        browserView.configuration.userContentController.addUserScript(script)
    }

    private func setupTrackingProtectionScripts() {
        browserView.configuration.userContentController.add(self, name: ScriptHandlers.focusTrackingProtection.rawValue)
        addScript(forResource: "preload", injectionTime: .atDocumentStart, forMainFrameOnly: true)
        browserView.configuration.userContentController.add(self, name: ScriptHandlers.focusTrackingProtectionPostLoad.rawValue)
        addScript(forResource: "postload", injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    }

    private func setupFindInPageScripts() {
        browserView.configuration.userContentController.add(self, name: ScriptHandlers.findInPageHandler.rawValue)
        addScript(forResource: "FindInPage", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }

    func disableTrackingProtection() {
        guard case .on = trackingProtectionStatus else { return }
        ScriptHandlers.allValues.forEach {
            browserView.configuration.userContentController.removeScriptMessageHandler(forName: $0.rawValue)
        }
        browserView.configuration.userContentController.removeAllUserScripts()
        browserView.configuration.userContentController.removeAllContentRuleLists()
        setupFindInPageScripts()
        trackingProtectionStatus = .off
    }

    func enableTrackingProtection() {
        guard case .off = trackingProtectionStatus else { return }

        setupBlockLists()
        setupTrackingProtectionScripts()
        trackingProtectionStatus = .on(TPPageStats())
    }

    func evaluate(_ javascript: String, completion: ((Any?, Error?) -> Void)?) {
        browserView.evaluateJavaScript(javascript, completionHandler: completion)
    }

    override func viewDidLoad() {
        self.browserView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let kp = keyPath, let path = KVOConstants(rawValue: kp) else {
            assertionFailure("Unhandled KVO key: \(keyPath ?? "nil")")
            return
        }

        switch path {
        case .URL:
            guard let url = browserView.url else { break }
            delegate?.webControllerURLDidChange(self, url: url)
        case .canGoBack:
            guard let canGoBack = change?[.newKey] as? Bool else { break }
            delegate?.webController(self, didUpdateCanGoBack: canGoBack)
        case .canGoForward:
            guard let canGoForward = change?[.newKey] as? Bool else { break }
            delegate?.webController(self, didUpdateCanGoForward: canGoForward)
        }
    }
}

extension WebViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.webController(self, scrollViewDidScroll: scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.webController(self, scrollViewWillBeginDragging: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.webController(self, scrollViewDidEndDragging: scrollView)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return delegate?.webControllerShouldScrollToTop(self) ?? true
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        delegate?.webControllerDidStartNavigation(self)
        if case .on = trackingProtectionStatus { trackingInformation = TPPageStats() }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.webControllerDidFinishNavigation(self)
        self.resetUA()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.webController(self, didFailNavigationWithError: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let error = error as NSError
        guard error.code != Int(CFNetworkErrors.cfurlErrorCancelled.rawValue), let errorUrl = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL else { return }
        let errorPageData = ErrorPage(error: error).data
        webView.load(errorPageData, mimeType: "", characterEncodingName: UIConstants.strings.encodingNameUTF8, baseURL: errorUrl)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let present: (UIViewController) -> Void = { self.present($0, animated: true, completion: nil) }

        switch navigationAction.navigationType {
            case .backForward:
                let navigatingBack = webView.backForwardList.backList.filter { $0 == currentBackForwardItem }.count == 0
                if navigatingBack {
                    delegate?.webControllerDidNavigateBack(self)
                } else {
                    delegate?.webControllerDidNavigateForward(self)
                }
            case .reload:
                delegate?.webControllerDidReload(self)
            default:
                break
        }

        currentBackForwardItem = webView.backForwardList.currentItem

        // prevent Focus from opening universal links
        // https://stackoverflow.com/questions/38450586/prevent-universal-links-from-opening-in-wkwebview-uiwebview
        let allowDecision = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2) ?? .allow

        let decision: WKNavigationActionPolicy = RequestHandler().handle(request: navigationAction.request, alertCallback: present) ? allowDecision : .cancel
        if navigationAction.navigationType == .linkActivated && browserView.url != navigationAction.request.url {
            Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.click, object: TelemetryEventObject.websiteLink)
        }
        decisionHandler(decision)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        delegate?.webControllerDidStartProvisionalNavigation(self)
    }
}

extension WebViewController: BrowserState {
    var canGoBack: Bool { return browserView.canGoBack }
    var canGoForward: Bool { return browserView.canGoForward }
    var estimatedProgress: Double { return browserView.estimatedProgress }
    var isLoading: Bool { return browserView.isLoading }
    var url: URL? { return browserView.url }
}

extension WebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            browserView.load(navigationAction.request)
        }

        return nil
    }
}

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "findInPageHandler" {
            let data = message.body as! [String: Int]

            // We pass these separately as they're sent in different messages to the userContentController
            if let currentResult = data["currentResult"] {
                delegate?.webController(self, didUpdateFindInPageResults: currentResult, totalResults: nil)
            }

            if let totalResults = data["totalResults"] {
                delegate?.webController(self, didUpdateFindInPageResults: nil, totalResults: totalResults)
            }
            return
        }

        guard let body = message.body as? [String: String],
            let urlString = body["url"],
            var components = URLComponents(string: urlString) else {
                return
        }

        components.scheme = "http"
        guard let url = components.url else { return }

        let enabled = Utils.getEnabledLists().compactMap { BlocklistName(rawValue: $0) }
        TPStatsBlocklistChecker.shared.isBlocked(url: url, enabledLists: enabled).uponQueue(.main) { listItem in
            if let listItem = listItem {
                self.trackingInformation = self.trackingInformation.create(byAddingListItem: listItem)
            }
        }
    }
}

extension WebViewController {
    func createPasswordManagerExtensionItem() {
        OnePasswordExtension.shared().createExtensionItem(forWebView: browserView, completion: {(extensionItem, error) -> Void in
            if extensionItem == nil {
                return
            }
            // Set the 1Password extension item property
            self.onePasswordExtensionItem = extensionItem
        })
    }

    func fillPasswords(returnedItems: [AnyObject]) {
        OnePasswordExtension.shared().fillReturnedItems(returnedItems, intoWebView: browserView, completion: { (success, returnedItemsError) -> Void in
            if !success {
                return
            }
        })
    }
}
