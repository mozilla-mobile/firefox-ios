/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit
import PassKit
import Combine
import Glean

protocol LegacyBrowserState {
    var url: URL? { get }
    var isLoading: Bool { get }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    var estimatedProgress: Double { get }
}

protocol LegacyWebController {
    var delegate: LegacyWebControllerDelegate? { get set }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }

    func load(_ request: URLRequest)
}

protocol LegacyWebControllerDelegate: AnyObject {
    func webControllerDidStartProvisionalNavigation(_ controller: LegacyWebController)
    func webControllerDidStartNavigation(_ controller: LegacyWebController)
    func webControllerDidFinishNavigation(_ controller: LegacyWebController)
    func webControllerDidNavigateBack(_ controller: LegacyWebController)
    func webControllerDidNavigateForward(_ controller: LegacyWebController)
    func webControllerDidReload(_ controller: LegacyWebController)
    func webControllerURLDidChange(_ controller: LegacyWebController, url: URL)
    func webController(_ controller: LegacyWebController, didFailNavigationWithError error: Error)
    func webController(_ controller: LegacyWebController, didUpdateCanGoBack canGoBack: Bool)
    func webController(_ controller: LegacyWebController, didUpdateCanGoForward canGoForward: Bool)
    func webController(_ controller: LegacyWebController, didUpdateEstimatedProgress estimatedProgress: Double)
    func webController(_ controller: LegacyWebController, scrollViewWillBeginDragging scrollView: UIScrollView)
    func webController(_ controller: LegacyWebController, scrollViewDidEndDragging scrollView: UIScrollView)
    func webController(_ controller: LegacyWebController, scrollViewDidScroll scrollView: UIScrollView)
    func webControllerShouldScrollToTop(_ controller: LegacyWebController) -> Bool
    func webController(_ controller: LegacyWebController, didUpdateTrackingProtectionStatus trackingStatus: TrackingProtectionStatus, oldTrackingProtectionStatus: TrackingProtectionStatus)
    func webController(_ controller: LegacyWebController, didUpdateFindInPageResults currentResult: Int?, totalResults: Int?)
}

class LegacyWebViewController: UIViewController, LegacyWebController {
    private enum ScriptHandlers: String, CaseIterable {
        case focusTrackingProtection
        case focusTrackingProtectionPostLoad
        case findInPageHandler
        case fullScreen
        case metadata
        case adsMessageHandler
    }

    private enum KVOConstants: String, CaseIterable {
        case URL
        case canGoBack
        case canGoForward
    }

    weak var delegate: LegacyWebControllerDelegate?

    var browserView: WKWebView! {
        didSet {
            configureRefreshControl()
        }
    }

    private var progressObserver: NSKeyValueObservation?
    private var currentBackForwardItem: WKBackForwardListItem?
    private let trackingProtectionManager: TrackingProtectionManager
    private var cancellable: AnyCancellable?
    private var menuAction: WebMenuAction

    var pageTitle: String? {
        return browserView.title
    }

    private var currentContentMode: WKWebpagePreferences.ContentMode?
    private var contentModeForHost: [String: WKWebpagePreferences.ContentMode] = [:]

    var requestMobileSite: Bool { currentContentMode == .desktop }
    var connectionIsSecure: Bool {
        return browserView.hasOnlySecureContent
    }

    var printFormatter: UIPrintFormatter { return browserView.viewPrintFormatter() }
    var scrollView: UIScrollView { return browserView.scrollView }

    var adsTelemetryHelper = AdsTelemetryHelper()
    var searchInContentTelemetry: SearchInContentTelemetry?

    init(trackingProtectionManager: TrackingProtectionManager, webMenuAction: WebMenuAction) {
        self.trackingProtectionManager = trackingProtectionManager
        self.menuAction = webMenuAction
        super.init(nibName: nil, bundle: nil)
        cancellable = self.trackingProtectionManager.$trackingProtectionStatus.sink { [weak self] status in
            guard let self = self else { return }
            self.delegate?.webController(self, didUpdateTrackingProtectionStatus: status, oldTrackingProtectionStatus: self.trackingProtectionManager.trackingProtectionStatus)
        }
        setupWebview()
        ContentBlockerHelper.shared.handler = reloadBlockers(_:)
        adsTelemetryHelper.getURL = { [weak self] in
            guard let self = self else { return nil }
            return self.url
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func reset() {
        browserView.load(URLRequest(url: URL(string: "about:blank", invalidCharacters: false)!))
        browserView.navigationDelegate = nil
        browserView.removeFromSuperview()
        setupWebview()
        self.browserView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
    }

    // Browser proxy methods
    func load(_ request: URLRequest) {
        browserView.load(request)
    }

    func goBack() {
        browserView.goBack()
    }

    func goForward() {
        browserView.goForward()
    }

    func reload() {
        browserView.reload()
    }

    func requestUserAgentChange() {
        if let hostName = browserView.url?.host {
            contentModeForHost[hostName] = requestMobileSite ? .mobile : .desktop
        }

        self.browserView.reloadFromOrigin()
    }

    func stop() { browserView.stopLoading() }

    private func setupWebview() {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        configuration.allowsInlineMediaPlayback = true
        configuration.ignoresViewportScaleLimits = true

        // For consistency we set our user agent similar to Firefox iOS.
        //
        // Important to note that this UA change only applies when the webview is created initially or
        // when people hit the erase session button. The UA is not changed when you change the width of
        // Focus on iPad, which means there could be some edge cases right now.

        if UIDevice.current.userInterfaceIdiom == .pad {
            configuration.applicationNameForUserAgent = "Version/13.1 Safari/605.1.15"
        } else {
            configuration.applicationNameForUserAgent = "FxiOS/\(AppInfo.majorVersion) Mobile/15E148 Version/15.0"
        }

        if #available(iOS 15.0, *) {
            configuration.upgradeKnownHostsToHTTPS = true
        }
        browserView = WKWebView(frame: .zero, configuration: configuration)

        browserView.allowsBackForwardNavigationGestures = true
        browserView.allowsLinkPreview = true
        browserView.scrollView.clipsToBounds = false
        browserView.scrollView.delegate = self
        browserView.navigationDelegate = self
        browserView.uiDelegate = self

        progressObserver = browserView.observe(\WKWebView.estimatedProgress) { (webView, value) in
            self.delegate?.webController(self, didUpdateEstimatedProgress: webView.estimatedProgress)
        }

        if case .on = trackingProtectionManager.trackingProtectionStatus {
            setupBlockLists()
            setupTrackingProtectionScripts()
        }
        setupFindInPageScripts()
        setupMetadataScripts()
        setupFullScreen()
        setupAdsScripts()

        view.addSubview(browserView)
        browserView.snp.makeConstraints { make in
            make.edges.equalTo(view.snp.edges)
        }

        KVOConstants.allCases.forEach { browserView.addObserver(self, forKeyPath: $0.rawValue, options: .new, context: nil) }
    }

    @objc
    private func reloadBlockers(_ blockLists: [WKContentRuleList]) {
        DispatchQueue.main.async {
            self.browserView.configuration.userContentController.removeAllContentRuleLists()
            blockLists.forEach(self.browserView.configuration.userContentController.add)
        }
    }

    private func setupBlockLists() {
        ContentBlockerHelper.shared.getBlockLists { [weak self] lists in
            guard let self = self else { return }
            self.reloadBlockers(lists)
        }
    }

    private func configureRefreshControl() {
        scrollView.refreshControl = UIRefreshControl()
        scrollView.refreshControl?.addTarget(self, action: #selector(reloadPage), for: .valueChanged)
    }

    @objc
    private func reloadPage() {
        reload()
        DispatchQueue.main.async {
            self.scrollView.refreshControl?.endRefreshing()
        }
    }

    private func addScript(forResource resource: String, injectionTime: WKUserScriptInjectionTime, forMainFrameOnly mainFrameOnly: Bool) {
        do {
            let source = try String(contentsOf: Bundle.main.url(forResource: resource, withExtension: "js")!)
            let script = WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: mainFrameOnly)
            browserView.configuration.userContentController.addUserScript(script)
        } catch {
            fatalError("Invalid data in file \(resource)")
        }
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

    private func setupMetadataScripts() {
        browserView.configuration.userContentController.add(self, name: ScriptHandlers.metadata.rawValue)
        addScript(forResource: "MetadataHelper", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }

    private func setupFullScreen() {
        browserView.configuration.userContentController.add(self, name: ScriptHandlers.fullScreen.rawValue)
        addScript(forResource: "FullScreen", injectionTime: .atDocumentEnd, forMainFrameOnly: true)
    }

    private func setupAdsScripts() {
        browserView.configuration.userContentController.add(self, name: ScriptHandlers.adsMessageHandler.rawValue)
        addScript(forResource: "Ads", injectionTime: .atDocumentEnd, forMainFrameOnly: false)
    }

    func disableTrackingProtection() {
        guard case .on = trackingProtectionManager.trackingProtectionStatus else { return }
        ScriptHandlers.allCases.forEach {
            browserView.configuration.userContentController.removeScriptMessageHandler(forName: $0.rawValue)
        }
        browserView.configuration.userContentController.removeAllUserScripts()
        browserView.configuration.userContentController.removeAllContentRuleLists()
        setupFindInPageScripts()
        setupMetadataScripts()
        setupFullScreen()
        setupAdsScripts()
        trackingProtectionManager.trackingProtectionStatus = .off
    }

    func enableTrackingProtection() {
        guard case .off = trackingProtectionManager.trackingProtectionStatus else { return }
        setupBlockLists()
        setupTrackingProtectionScripts()
        trackingProtectionManager.trackingProtectionStatus = .on(TPPageStats())
    }

    func evaluate(_ javascript: String, completion: ((Any?, Error?) -> Void)?) {
        browserView.evaluateJavaScript(javascript, completionHandler: completion)
    }

    func evaluateDocumentContentType(_ completion: @escaping (String?) -> Void) {
        evaluate("document.contentType") { documentType, _ in
            completion(documentType as? String)
        }
    }

    enum MetadataError: Swift.Error {
        case missingMetadata
        case missingURL
    }

    /// Get the metadata out of the page-metadata-parser, and into a type safe struct as soon as possible.
    ///
    func getMetadata(completion: @escaping (Swift.Result<Metadata, Error>) -> Void) {
        evaluate("__firefox__.metadata.getMetadata()") { result, error in
            let metadata = result
                .flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                .flatMap { try? JSONDecoder().decode(Metadata.self, from: $0) }

            if let metadata = metadata {
                completion(.success(metadata))
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(MetadataError.missingMetadata))
            }
        }
    }

    func getMetadata() -> Future<Metadata, Error> {
        Future { [weak self] promise in
            guard let self = self else { return }
            self.getMetadata { result in
                promise(result)
            }
        }
    }

    func getMetadata() async throws -> Metadata {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else { return }
            self.getMetadata { result in
                continuation.resume(with: result)
            }
        }
    }

    func focus() {
        browserView.becomeFirstResponder()
    }

    func resetZoom() {
        browserView.scrollView.setZoomScale(1.0, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.browserView.addObserver(self, forKeyPath: "URL", options: .new, context: nil)
        searchInContentTelemetry = SearchInContentTelemetry()
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

extension LegacyWebViewController: UIScrollViewDelegate {
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

extension LegacyWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        // validate the URL using URIFixup
        guard let urlString = webView.url?.absoluteString,
              URIFixup.getURL(entry: urlString) != nil else {
            // URL failed validation, prevent loading
            stop()
            return
        }
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        delegate?.webControllerDidStartNavigation(self)
        trackingProtectionManager.trackingProtectionStatus.trackingInformation = TPPageStats()
        currentContentMode = navigation?.effectiveContentMode
        searchInContentTelemetry?.setSearchType(webView: webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.webControllerDidFinishNavigation(self)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        GleanMetrics.Webview.fail.record()

        delegate?.webController(self, didFailNavigationWithError: error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        GleanMetrics.Webview.failProvisional.record()

        let error = error as NSError
        guard error.code != Int(CFNetworkErrors.cfurlErrorCancelled.rawValue), let errorUrl = error.userInfo[NSURLErrorFailingURLErrorKey] as? URL else { return }
        let errorPageData = ErrorPage(error: error).data
        webView.load(errorPageData, mimeType: "", characterEncodingName: UIConstants.strings.encodingNameUTF8, baseURL: errorUrl)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        if let redirectedURL = navigationAction.request.url {
            adsTelemetryHelper.trackClickedAds(with: redirectedURL)
        }

        // If the user has asked for a specific content mode for this host, use that.
        if let hostName = navigationAction.request.url?.host, let preferredContentMode = contentModeForHost[hostName] {
            preferences.preferredContentMode = preferredContentMode
        }

        let present: (UIViewController) -> Void = {
            self.present($0, animated: true) {
                self.delegate?.webController(self, didUpdateEstimatedProgress: 1.0)
                self.delegate?.webControllerDidFinishNavigation(self)
            }
        }

        switch navigationAction.navigationType {
        case .backForward:
            let navigatingBack = !webView.backForwardList.backList.contains(where: { $0 == currentBackForwardItem })
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

        // Prevent Focus from opening deeplinks from links
        if let scheme = navigationAction.request.url?.scheme,
           scheme.caseInsensitiveCompare(AppInfo.appScheme) == .orderedSame {
            decisionHandler(.cancel, preferences)
            return
        }

        currentBackForwardItem = webView.backForwardList.currentItem
        // prevent Focus from opening universal links
        // https://stackoverflow.com/questions/38450586/prevent-universal-links-from-opening-in-wkwebview-uiwebview
        let allowDecision = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2) ?? .allow

        let decision: WKNavigationActionPolicy = RequestHandler().handle(request: navigationAction.request, alertCallback: present) ? allowDecision : .cancel

        decisionHandler(decision, preferences)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let response = navigationResponse.response

        guard let responseMimeType = response.mimeType else {
            decisionHandler(.allow)
            return
        }

        // Check for passbook response
        if responseMimeType == "application/vnd.apple.pkpass" {
            decisionHandler(.allow)
            browserView.load(URLRequest(url: URL(string: "about:blank", invalidCharacters: false)!))

            func presentPassErrorAlert() {
                let passErrorAlert = UIAlertController(title: UIConstants.strings.addPassErrorAlertTitle, message: UIConstants.strings.addPassErrorAlertMessage, preferredStyle: .alert)
                let passErrorDismissAction = UIAlertAction(title: UIConstants.strings.addPassErrorAlertDismiss, style: .default) { (UIAlertAction) in
                    passErrorAlert.dismiss(animated: true, completion: nil)
                }
                passErrorAlert.addAction(passErrorDismissAction)
                self.present(passErrorAlert, animated: true, completion: nil)
            }

            guard let responseURL = response.url else {
                presentPassErrorAlert()
                return
            }

            guard let passData = try? Data(contentsOf: responseURL) else {
                presentPassErrorAlert()
                return
            }

            guard let pass = try? PKPass(data: passData) else {
                // Alert user to add pass failure
                presentPassErrorAlert()
                return
            }

            // Present pass
            let passLibrary = PKPassLibrary()
            if passLibrary.containsPass(pass) {
                UIApplication.shared.open(pass.passURL!, options: [:])
            } else {
                guard let addController = PKAddPassesViewController(pass: pass) else {
                    presentPassErrorAlert()
                    return
                }
                self.present(addController, animated: true, completion: nil)
            }

            return
        }

        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        delegate?.webControllerDidStartProvisionalNavigation(self)
    }
}

extension LegacyWebViewController: LegacyBrowserState {
    var canGoBack: Bool { return browserView.canGoBack }
    var canGoForward: Bool { return browserView.canGoForward }
    var estimatedProgress: Double { return browserView.estimatedProgress }
    var isLoading: Bool { return browserView.isLoading }
    var url: URL? { return browserView.url }
}

extension LegacyWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // check if this is a new frame / window
        guard navigationAction.targetFrame == nil else { return nil }

        // Prevent Focus from opening deeplinks from links
        if let scheme = navigationAction.request.url?.scheme,
           scheme.caseInsensitiveCompare(AppInfo.appScheme) == .orderedSame {
            return nil
        }

        // If URL is a file:// when web application calls window.open() or fails validation, prevent loading
        guard let url = navigationAction.request.url,
              let validatedURL = URIFixup.getURL(entry: url.absoluteString) else {
            return nil
        }

        // load validated URLs
        browserView.load(URLRequest(url: validatedURL))

        // we return nil to not open new window
        return nil
    }
}

extension LegacyWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // FXIOS-8090 - #19152 ⁃ Integrate EngineSession ads handler in Focus iOS
        if message.name == "adsMessageHandler" {
            adsTelemetryHelper.trackAds(message: message)
        }

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

        // FXIOS-8643 - #19166 ⁃ Integrate content blocking in Focus iOS
        let enabled = Utils.getEnabledLists().compactMap { BlocklistName(rawValue: $0) }
        TPStatsBlocklistChecker.shared.isBlocked(url: url, enabledLists: enabled).uponQueue(.main) { [unowned self] listItem in
            if let listItem = listItem {
                let currentInfo = trackingProtectionManager.trackingProtectionStatus.trackingInformation
                trackingProtectionManager.trackingProtectionStatus.trackingInformation = currentInfo.map { $0.create(byAddingListItem: listItem) }
            }
        }
    }
}

extension LegacyWebViewController {
    func webView(_ webView: WKWebView, contextMenuConfigurationFor elementInfo: WKContextMenuElementInfo) async -> UIContextMenuConfiguration? {
        guard let url = elementInfo.linkURL else { return nil }

        return UIContextMenuConfiguration(identifier: nil) {
            let previewViewController = UIViewController()
            previewViewController.view.isUserInteractionEnabled = false
            let clonedWebView = WKWebView(frame: webView.frame, configuration: webView.configuration)

            previewViewController.view.addSubview(clonedWebView)
            clonedWebView.snp.makeConstraints { make in
                make.edges.equalTo(previewViewController.view)
            }

            clonedWebView.load(URLRequest(url: url))

            return previewViewController
        } actionProvider: { [unowned self] menu in
            UIMenu(title: url.absoluteString, children: [
                UIAction(self.menuAction.openLink(url: url)),
                UIAction(self.menuAction.openInDefaultBrowserItem(for: url)),
                UIAction(self.menuAction.copyItem(url: url)),
                UIAction(self.menuAction.sharePageItem(for: .init(url: url, webViewController: self), sender: self.view, presenter: self))
            ])
        }
    }
}
