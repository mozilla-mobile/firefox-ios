/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Account
import Shared

enum DismissType {
    case dismiss
    case popToRootVC
}

/**
 Show the FxA web content for signing in, signing up, or showing FxA settings.
 Messaging from the website to native is with WKScriptMessageHandler.
 */
class FxAWebViewController: UIViewController, WKNavigationDelegate {
    fileprivate let dismissType: DismissType
    fileprivate var webView: WKWebView
    /// Used to show a second WKWebView to browse help links.
    fileprivate var helpBrowser: WKWebView?
    fileprivate let viewModel: FxAWebViewModel

    /**
     init() FxAWebView.

     - parameter pageType: Specify login flow or settings page if already logged in.
     - parameter profile: a Profile.
     - parameter dismissalStyle: depending on how this was presented, it uses modal dismissal, or if part of a UINavigationController stack it will pop to the root.
     - parameter deepLinkParams: URL args passed in from deep link that propagate to FxA web view
     */
    init(pageType: FxAPageType, profile: Profile, dismissalStyle: DismissType, deepLinkParams: FxALaunchParams?) {
        self.viewModel = FxAWebViewModel(pageType: pageType, profile: profile, deepLinkParams: deepLinkParams)
        
        self.dismissType = dismissalStyle

        let contentController = WKUserContentController()
        viewModel.setupUserScript(for: contentController)
 
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsLinkPreview = false
        webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
        webView.scrollView.bounces = false  // Don't allow overscrolling.
        webView.customUserAgent = FxAWebViewModel.mobileUserAgent

        super.init(nibName: nil, bundle: nil)
        contentController.add(self, name: "accountsCommandHandler")
        webView.navigationDelegate = self
        webView.uiDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    private func setup() {
        webView.navigationDelegate = self
        view = webView
        
        viewModel.setupFirstPage { [weak self] (request, telemetryEventMethod) in
            if let method = telemetryEventMethod {
                TelemetryWrapper.recordEvent(category: .firefoxAccount, method: method, object: .accountConnected)
            }
            self?.webView.load(request)
        }
        
        viewModel.onDismissController = { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    /**
     Dismiss according the `dismissType`, depending on whether this view was presented modally or on navigation stack.
     */
    override func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        if dismissType == .dismiss {
            super.dismiss(animated: animated, completion: completion)
        } else {
            navigationController?.popToRootViewController(animated: true)
            completion?()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let decision = viewModel.shouldAllowRedirectAfterLogIn(basedOn: navigationAction.request.url)
        decisionHandler(decision)
    }
}

extension FxAWebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        viewModel.handle(scriptMessage: message)
    }
}

extension FxAWebViewController {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let hideLongpress = "document.body.style.webkitTouchCallout='none';"
        webView.evaluateJavaScript(hideLongpress)

        //The helpBrowser shows the current URL in the navbar, the main fxa webview does not.
        guard webView !== helpBrowser else {
            navigationItem.title = viewModel.composeTitle(basedOn: webView.url, hasOnlySecureContent: webView.hasOnlySecureContent)
            return
        }

        navigationItem.title = nil
    }
}

extension FxAWebViewController: WKUIDelegate {
    
    /// Blank target links (support links) will create a 2nd webview (the `helpBrowser`) to browse. This webview will have a close button in the navigation bar to go back to the main fxa webview.
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard helpBrowser == nil else {
            return nil
        }
        let f = webView.frame
        let wv = WKWebView(frame: CGRect(width: f.width, height: f.height), configuration: configuration)
        helpBrowser?.load(navigationAction.request)
        webView.addSubview(wv)
        helpBrowser = wv
        helpBrowser?.navigationDelegate = self

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: Strings.BackTitle, style: .plain, target: self, action: #selector(closeHelpBrowser))

        return helpBrowser
    }

    @objc func closeHelpBrowser() {
        UIView.animate(withDuration: 0.2, animations: {
            self.helpBrowser?.alpha = 0
        }, completion: {_ in
            self.helpBrowser?.removeFromSuperview()
            self.helpBrowser = nil
        })

        navigationItem.title = nil
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = false
    }
}
