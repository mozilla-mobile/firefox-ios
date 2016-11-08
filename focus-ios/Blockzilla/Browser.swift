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

    override init() {
        super.init()

        createWebView()

        KeyboardHelper.defaultHelper.addDelegate(delegate: self)

        NotificationCenter.default.addObserver(self, selector: #selector(progressChanged(notification:)), name: Notification.Name(rawValue: "WebProgressEstimateChangedNotification"), object: nil)
    }

    var bottomInset: Float = 0 {
        didSet {
            webView.scrollView.contentInset.bottom = CGFloat(bottomInset)
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

        if request.mainDocumentURL != url {
            url = request.mainDocumentURL
        }

        updateBackForwardStates(webView)

        if request.mainDocumentURL == request.url {
            isLoading = true
            delegate?.browserDidStartNavigation(self)
        }

        return true
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        updateBackForwardStates(webView)

        if !webView.isLoading, isLoading {
            isLoading = false
            delegate?.browserDidFinishNavigation(self)
        }
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        updateBackForwardStates(webView)

        if !webView.isLoading, isLoading {
            isLoading = false
            delegate?.browser(self, didFailNavigationWithError: error)
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

extension Browser: KeyboardHelperDelegate {
    public func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        // When an input field is focused, the web view adds 44 to the bottom inset to make room for the bottom
        // input bar. Since this bar overlaps the browser toolbar, we don't need the additional bottom inset,
        // so reset it here.
        let height = state.intersectionHeightForView(view: view)
        webView.scrollView.contentInset.bottom = max(height, CGFloat(bottomInset))
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        // As mentioned above, the webview adds 44 to the bottom inset during input. When the keyboard is hidden,
        // the web view will then remove 44 from the inset to restore the original state. Since we already removed
        // the extra inset above, reset it here to prevent it from being removed again.
        webView.scrollView.contentInset.bottom = CGFloat(bottomInset)
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {}
}
