/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

protocol BrowserDelegate: class {
    func browserDidStartNavigation(_ browser: Browser)
    func browserDidFinishNavigation(_ browser: Browser)
    func browser(_ browser: Browser, didFailNavigationWithError error: Error)
    func browser(_ browser: Browser, didUpdateCanGoBack canGoBack: Bool)
    func browser(_ browser: Browser, didUpdateCanGoForward canGoForward: Bool)
    func browser(_ browser: Browser, didUpdateEstimatedProgress estimatedProgress: Float)
    func browser(_ browser: Browser, didUpdateURL url: URL?)
}

class Browser: NSObject {
    weak var delegate: BrowserDelegate?

    let view = UIView()

    fileprivate var webView: UIWebView!

    /// The main document of the latest request, which might be set before we've actually
    /// started loading the document.
    fileprivate var pendingURL: URL?

    override init() {
        super.init()

        LocalContentBlocker.delegate = self
        createWebView()

        KeyboardHelper.defaultHelper.addDelegate(delegate: self)

        NotificationCenter.default.addObserver(self, selector: #selector(progressChanged(notification:)), name: Notification.Name(rawValue: "WebProgressEstimateChangedNotification"), object: nil)
    }

    var bottomInset: Float = 0 {
        didSet {
            webView.scrollView.contentInset.bottom = CGFloat(bottomInset)
            webView.scrollView.scrollIndicatorInsets.bottom = CGFloat(bottomInset)
        }
    }

    private func createWebView() {
        webView = UIWebView()
        webView.scalesPageToFit = true
        webView.delegate = self
        webView.scrollView.backgroundColor = UIConstants.colors.background
        webView.scrollView.contentInset.bottom = CGFloat(bottomInset)
        webView.mediaPlaybackRequiresUserAction = true
        view.addSubview(webView)

        webView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }

    func reset() {
        webView.delegate = nil
        webView.removeFromSuperview()

        isLoading = false
        canGoBack = false
        canGoForward = false
        estimatedProgress = -1
        url = nil

        createWebView()
    }

    func goBack() {
        return webView.goBack()
    }

    func goForward() {
        return webView.goForward()
    }

    func reload() {
        webView.reload()
    }

    func loadRequest(_ request: URLRequest) {
        isLoading = true
        webView.loadRequest(request)
    }

    func stop() {
        webView.stopLoading()
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
    private static let supportedSchemes = ["http", "https", "about"]

    func webViewDidStartLoad(_ webView: UIWebView) {
        if estimatedProgress == 0 {
            estimatedProgress = 0.1
        }

        updateBackForwardStates(webView)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        // We don't currently support opening in external apps, so just ignore unsupported schemes.
        guard let scheme = request.url?.scheme, Browser.supportedSchemes.contains(scheme.lowercased()) else { return false }

        updateBackForwardStates(webView)

        if request.mainDocumentURL == request.url {
            isLoading = true
            delegate?.browserDidStartNavigation(self)
        }

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
        if !webView.isLoading, isLoading {
            isLoading = false
            delegate?.browser(self, didFailNavigationWithError: error)
        }

        updatePostLoad()
    }

    private func updatePostLoad() {
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

extension Browser: KeyboardHelperDelegate {
    public func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        // Only update the insets if the keyboard is being presented for this browser.
        guard webView.hasFirstResponder else { return }

        // When an input field is focused, the web view adds 44 to the bottom inset to make room for the bottom
        // input bar. Since this bar overlaps the browser toolbar, we don't need the additional bottom inset,
        // so reset it here.
        let inset = max(state.intersectionHeightForView(view: view), CGFloat(bottomInset))
        webView.scrollView.contentInset.bottom = inset
        webView.scrollView.scrollIndicatorInsets.bottom = inset
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {}
    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {}

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidHideWithState state: KeyboardState) {
        // As mentioned above, the webview adds 44 to the bottom inset during input. When the keyboard is hidden,
        // the web view will then remove 44 from the inset to restore the original state. Since we already removed
        // the extra inset above, reset it here to prevent it from being removed again.
        webView.scrollView.contentInset.bottom = CGFloat(bottomInset)
        webView.scrollView.scrollIndicatorInsets.bottom = CGFloat(bottomInset)
    }
}
