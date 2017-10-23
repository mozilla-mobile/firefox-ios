/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit

protocol BrowserState {
    var url: URL? { get }
    var isLoading: Bool { get }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    var estimatedProgress: Double { get }
}

protocol WebController {
    weak var delegate: WebControllerDelegate? { get set }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }

    func load(_ request: URLRequest)
}

protocol WebControllerDelegate: class {
    func webControllerDidStartNavigation(_ controller: WebController)
    func webControllerDidFinishNavigation(_ controller: WebController)
    func webController(_ controller: WebController, didFailNavigationWithError error: Error)
    func webController(_ controller: WebController, didUpdateCanGoBack canGoBack: Bool)
    func webController(_ controller: WebController, didUpdateCanGoForward canGoForward: Bool)
    func webController(_ controller: WebController, didUpdateEstimatedProgress estimatedProgress: Double)
    func webController(_ controller: WebController, scrollViewWillBeginDragging scrollView: UIScrollView)
    func webController(_ controller: WebController, scrollViewDidEndDragging scrollView: UIScrollView)
    func webController(_ controller: WebController, scrollViewDidScroll scrollView: UIScrollView)
    func webController(_ controller: WebController, stateDidChange state: BrowserState)
    func webControllerShouldScrollToTop(_ controller: WebController) -> Bool
}



class WebViewController: UIViewController, WebController {
    weak var delegate: WebControllerDelegate?

    private var browserView = WKWebView()
    private var progressObserver: NSKeyValueObservation?

    var printFormatter: UIPrintFormatter { return browserView.viewPrintFormatter() }
    var scrollView: UIScrollView { return browserView.scrollView }

    convenience init() {
        self.init(nibName: nil, bundle: nil)
        setupWebview()
        ContentBlockerHelper.shared.handler = reloadBlockers(_:)
    }

    func reset() {
        browserView.load(URLRequest(url: URL(string: "about:blank")!))
        browserView.navigationDelegate = nil
        browserView.removeFromSuperview()
        browserView = WKWebView()
        setupWebview()
    }

    // Browser proxy methods
    func load(_ request: URLRequest) { browserView.load(request) }
    func goBack() { browserView.goBack() }
    func goForward() { browserView.goForward() }
    func reload() { browserView.reload() }
    func stop() { browserView.stopLoading() }

    private func setupWebview() {
        browserView.allowsBackForwardNavigationGestures = true
        browserView.allowsLinkPreview = false
        browserView.scrollView.clipsToBounds = false
        browserView.scrollView.delegate = self
        browserView.navigationDelegate = self
        browserView.uiDelegate = self
        progressObserver = browserView.observe(\WKWebView.estimatedProgress) { (webView, value) in
            self.delegate?.webController(self, didUpdateEstimatedProgress: webView.estimatedProgress)
        }

        ContentBlockerHelper.shared.getBlockLists { lists in
            self.reloadBlockers(lists)
        }

        view.addSubview(browserView)
        browserView.snp.makeConstraints { make in
            make.edges.equalTo(view.snp.edges)
        }
    }

    @objc private func reloadBlockers(_ blockLists: [WKContentRuleList]) {
        DispatchQueue.main.async {
            self.browserView.configuration.userContentController.removeAllContentRuleLists()
            blockLists.forEach(self.browserView.configuration.userContentController.add)
        }
    }

    fileprivate func updateBackForwardState(webView: WKWebView) {
        delegate?.webController(self, didUpdateCanGoBack: canGoBack)
        delegate?.webController(self, didUpdateCanGoForward: canGoForward)
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
        updateBackForwardState(webView: webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        delegate?.webControllerDidFinishNavigation(self)    
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.webController(self, didFailNavigationWithError: error)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let present: (UIViewController) -> Void = { self.present($0, animated: true, completion: nil) }
        let decision: WKNavigationActionPolicy = RequestHandler().handle(request: navigationAction.request, alertCallback: present) ? .allow : .cancel
        decisionHandler(decision)
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
