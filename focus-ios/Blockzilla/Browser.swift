/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry

protocol BrowserDelegate: class {
    func browserDidStartNavigation(_ browser: Browser)
    func browserDidFinishNavigation(_ browser: Browser)
    func browser(_ browser: Browser, didFailNavigationWithError error: Error)
    func browser(_ browser: Browser, didUpdateCanGoBack canGoBack: Bool)
    func browser(_ browser: Browser, didUpdateCanGoForward canGoForward: Bool)
    func browser(_ browser: Browser, didUpdateEstimatedProgress estimatedProgress: Float)
    func browser(_ browser: Browser, didUpdateURL url: URL?)
    func browser(_ browser: Browser, shouldStartLoadWith request: URLRequest) -> Bool
    func browser(_ browser: Browser, scrollViewWillBeginDragging scrollView: UIScrollView)
    func browser(_ browser: Browser, scrollViewDidEndDragging scrollView: UIScrollView)
    func browser(_ browser: Browser, scrollViewDidScroll scrollView: UIScrollView)
    func browserShouldScrollToTop(_ browser: Browser) -> Bool
}

class Browser: NSObject {
    weak var delegate: BrowserDelegate?

    let view = UIView()

    var scrollView: UIScrollView? {
        return webView?.scrollView
    }

    fileprivate var webView: UIWebView?

    /// The main document of the latest request, which might be set before we've actually
    /// started loading the document.
    fileprivate var pendingURL: URL?

    override init() {
        super.init()

        LocalContentBlocker.delegate = self
        createWebView()

        NotificationCenter.default.addObserver(self, selector: #selector(progressChanged(notification:)), name: Notification.Name(rawValue: "WebProgressEstimateChangedNotification"), object: nil)
    }

    private func createWebView() {
        let webView = UIWebView()
        webView.scalesPageToFit = true
        webView.mediaPlaybackRequiresUserAction = true
        webView.scrollView.backgroundColor = UIConstants.colors.background
        webView.scrollView.layer.masksToBounds = false
        webView.scrollView.delegate = self
        webView.delegate = self
        let swipeLeftRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(goForwardByGesture))
        swipeLeftRecognizer.direction = .left
        let swipeRightRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(goBackByGesture))
        swipeRightRecognizer.direction = .right
        webView.addGestureRecognizer(swipeLeftRecognizer)
        webView.addGestureRecognizer(swipeRightRecognizer)
        view.addSubview(webView)

        webView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }

        self.webView = webView
    }

    func reset() {
        webView?.loadRequest(URLRequest(url: URL(string: "about:blank")!))
        webView?.delegate = nil
        webView?.removeFromSuperview()
        webView = nil

        isLoading = false
        canGoBack = false
        canGoForward = false
        estimatedProgress = -1
        url = nil

        // WebKit apparently requires a small delay between recreating web views before
        // the back/forward cache is purged (see bug 1319297).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.createWebView()
        }
    }

    func goBackByGesture() {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.swipeToNavigateBack, object: TelemetryEventObject.app)
        goBack()
    }

    func goForwardByGesture() {
        Telemetry.default.recordEvent(category: TelemetryEventCategory.action, method: TelemetryEventMethod.swipeToNavigateForward, object: TelemetryEventObject.app)
        goForward()
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        webView?.reload()
    }

    func loadRequest(_ request: URLRequest) {
        isLoading = true
        webView?.loadRequest(request)
    }

    func stop() {
        webView?.stopLoading()
    }

    fileprivate(set) var isLoading = false {
        didSet {
            if isLoading && !oldValue {
                estimatedProgress = 0
            }

            if !isLoading {
                estimatedProgress = 1
            }
        }
    }

    fileprivate(set) var canGoBack = false {
        didSet {
            delegate?.browser(self, didUpdateCanGoBack: canGoBack)
        }
    }

    fileprivate(set) var canGoForward = false {
        didSet {
            delegate?.browser(self, didUpdateCanGoForward: canGoForward)
        }
    }

    fileprivate(set) var estimatedProgress: Float = -1 {
        didSet {
            if estimatedProgress != oldValue {
                delegate?.browser(self, didUpdateEstimatedProgress: estimatedProgress)
            }
        }
    }

    fileprivate(set) var url: URL? = nil {
        didSet {
            pendingURL = nil
            delegate?.browser(self, didUpdateURL: url)
        }
    }

    @objc private func progressChanged(notification: Notification) {
        guard let progress = notification.userInfo?["WebProgressEstimatedProgressKey"] as? Float, isLoading, progress > estimatedProgress else { return }
        estimatedProgress = progress
    }
}

extension Browser: UIWebViewDelegate {
    func webViewDidStartLoad(_ webView: UIWebView) {
        if estimatedProgress == 0 {
            estimatedProgress = 0.1
        }

        updateBackForwardStates(webView)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard delegate?.browser(self, shouldStartLoadWith: request) ?? true else { return false }

        // If the load isn't on the main frame, we don't need any other special handling.
        guard request.mainDocumentURL == request.url else {
            return true
        }

        // We can't detect universal links, so just disable them.
        if navigationType == .linkClicked {
            loadRequest(request)
            return false
        }

        isLoading = true
        delegate?.browserDidStartNavigation(self)

        updateBackForwardStates(webView)

        // Don't update the URL immediately since the requested page may not have started to load yet.
        // Instead, set a pending URL that we're expected to load, and update the URL when we receive
        // a response that matches this pending URL.
        pendingURL = request.mainDocumentURL

        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        if !webView.isLoading, isLoading {
            isLoading = false
            delegate?.browserDidFinishNavigation(self)
        }

        updatePostLoad()
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        updatePostLoad()

        if !webView.isLoading, isLoading {
            isLoading = false
            delegate?.browser(self, didFailNavigationWithError: error)
        }
    }

    private func updatePostLoad() {
        guard let webView = webView else { return }

        updateBackForwardStates(webView)

        // We'll usually get main document URL updates from LocalContentBlockerDelegate,
        // but certain events won't trigger a new page load (e.g., back/forward navigation).
        if url != webView.request?.mainDocumentURL {
            url = webView.request?.mainDocumentURL
        }
    }

    func updateBackForwardStates(_ webView: UIWebView) {
        if canGoBack != webView.canGoBack {
            canGoBack = webView.canGoBack
        }

        if canGoForward != webView.canGoForward {
            canGoForward = webView.canGoForward
        }
    }
}

extension Browser: LocalContentBlockerDelegate {
    func localContentBlocker(_ localContentBlocker: LocalContentBlocker, didReceiveDataForMainDocumentURL url: URL?) {
        // When we receive data for a URL, update the browser's URL if it changed and we were expecting this URL.
        if self.pendingURL == url {
            self.url = url
        }
    }
}

extension Browser: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        delegate?.browser(self, scrollViewDidScroll: scrollView)
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        delegate?.browser(self, scrollViewWillBeginDragging: scrollView)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        delegate?.browser(self, scrollViewDidEndDragging: scrollView)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return delegate?.browserShouldScrollToTop(self) ?? true
    }
}
