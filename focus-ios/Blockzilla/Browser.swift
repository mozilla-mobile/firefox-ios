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

    private var webView: UIWebView!

    override init() {
        super.init()

        createWebView()

        NotificationCenter.default.addObserver(self, selector: #selector(progressChanged(notification:)), name: Notification.Name(rawValue: "WebProgressEstimateChangedNotification"), object: nil)
    }

    private func createWebView() {
        webView = UIWebView()
        webView.delegate = self
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
        estimatedProgress = 0
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
        webView.loadRequest(request)
    }

    func stop() {
        webView.stopLoading()
    }

    fileprivate(set) var isLoading = false

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

    fileprivate(set) var estimatedProgress: Float = 0 {
        didSet {
            delegate?.browser(self, didUpdateEstimatedProgress: estimatedProgress)
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
    func webViewDidStartLoad(_ webView: UIWebView) {
        if estimatedProgress == 0 {
            estimatedProgress = 0.1
        }

        updateBackForwardStates(webView)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.mainDocumentURL != url {
            url = request.mainDocumentURL
        }

        updateBackForwardStates(webView)

        if request.mainDocumentURL == request.url, !isLoading {
            isLoading = true
            delegate?.browserDidStartNavigation(self)
            estimatedProgress = 0
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
