/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import Account
import MozillaAppServices
import Shared
import SwiftKeychainWrapper

enum DismissType {
    case dismiss
    case popToRootVC
}

enum FxAPageType {
    case emailLoginFlow
    case qrCode(url: String)
    case settingsPage
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
<<<<<<< HEAD
    fileprivate var deepLinkParams: FxALaunchParams?
=======
    
    fileprivate let viewModel: FxAWebViewModel
>>>>>>> removing logic from controller

    /**
     init() FxAWebView.

     - parameter pageType: Specify login flow or settings page if already logged in.
     - parameter profile: a Profile.
     - parameter dismissalStyle: depending on how this was presented, it uses modal dismissal, or if part of a UINavigationController stack it will pop to the root.
     - parameter: deepLinkParams: URL args passed in from deep link that propagate to FxA web view
     */
<<<<<<< HEAD
    init(pageType: FxAPageType, profile: Profile, dismissalStyle: DismissType, deepLinkParams: FxALaunchParams?) {
        self.pageType = pageType
        self.profile = profile
=======
    init(pageType: FxAPageType, profile: Profile, dismissalStyle: DismissType) {
        self.viewModel = FxAWebViewModel(pageType: pageType, profile: profile)
>>>>>>> removing logic from controller
        self.dismissType = dismissalStyle
        self.deepLinkParams = deepLinkParams

        let contentController = WKUserContentController()
        if let path = Bundle.main.path(forResource: "FxASignIn", ofType: "js"), let source = try? String(contentsOfFile: path, encoding: .utf8) {
            let userScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
            contentController.addUserScript(userScript)
        }
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsLinkPreview = false
        webView.accessibilityLabel = NSLocalizedString("Web content", comment: "Accessibility label for the main web content view")
        webView.scrollView.bounces = false  // Don't allow overscrolling.
        webView.customUserAgent = UserAgent.mobileUserAgent() // This is not shown full-screen, use mobile UA

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
        webView.navigationDelegate = self
        view = webView
<<<<<<< HEAD

        func makeRequest(_ url: URL) -> URLRequest {
            if let query = deepLinkParams?.query {
                let args = query.filter { $0.key.starts(with: "utm_") }.map {
                    return URLQueryItem(name: $0.key, value: $0.value)
                }

                var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)
                comp?.queryItems?.append(contentsOf: args)
                if let url = comp?.url {
                    return URLRequest(url: url)
                }
            }

            return URLRequest(url: url)
        }

        RustFirefoxAccounts.shared.accountManager.uponQueue(.main) { accountManager in
            accountManager.getManageAccountURL(entrypoint: "ios_settings_manage") { [weak self] result in
                guard let self = self else { return }

                // Handle authentication with either the QR code login flow, email login flow, or settings page flow
                switch self.pageType {
                case .emailLoginFlow:
                    accountManager.beginAuthentication { [weak self] result in
                        if case .success(let url) = result {
                            self?.baseURL = url
                            UnifiedTelemetry.recordEvent(category: .firefoxAccount, method: .emailLogin, object: .accountConnected)
                            self?.webView.load(makeRequest(url))
                        }
                    }
                case let .qrCode(url):
                    accountManager.beginPairingAuthentication(pairingUrl: url) { [weak self] result in
                        if case .success(let url) = result {
                            self?.baseURL = url
                            UnifiedTelemetry.recordEvent(category: .firefoxAccount, method: .qrPairing, object: .accountConnected)
                            self?.webView.load(makeRequest(url))
                        }
                    }
                case .settingsPage:
                    if case .success(let url) = result {
                        self.baseURL = url
                        self.webView.load(makeRequest(url))
                    }
                }
=======
        viewModel.webView = webView
        
        viewModel.authenticate()
        
        viewModel.onLoading = { [weak self] output in
            let (request, method) = output
            
            if let _method = method {
                UnifiedTelemetry.recordEvent(category: .firefoxAccount, method: _method, object: .accountConnected)
>>>>>>> removing logic from controller
            }
            self?.webView.load(request)
        }
        
        viewModel.onDismiss = { [weak self] in
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

        // Cancel navigation that happens after login to an account, which is when a redirect to `redirectURL` happens.
        // The app handles this event fully in native UI.
        let redirectUrl = RustFirefoxAccounts.redirectURL
        if let navigationURL = navigationAction.request.url {
            let expectedRedirectURL = URL(string: redirectUrl)!
            if navigationURL.scheme == expectedRedirectURL.scheme && navigationURL.host == expectedRedirectURL.host && navigationURL.path == expectedRedirectURL.path {
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }
}

extension FxAWebViewController: WKScriptMessageHandler {
   
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let url = viewModel.baseURL else { return }

        let origin = message.frameInfo.securityOrigin
        guard origin.`protocol` == url.scheme && origin.host == url.host && origin.port == (url.port ?? 0) else {
            print("Ignoring message - \(origin) does not match expected origin: \(url.origin ?? "nil")")
            return
        }

        guard message.name == "accountsCommandHandler" else { return }
        guard let body = message.body as? [String: Any], let detail = body["detail"] as? [String: Any],
        let msg = detail["message"] as? [String: Any], let cmd = msg["command"] as? String else {
            return
        }

        let id = Int(msg["messageId"] as? String ?? "")
        viewModel.handleRemote(command: cmd, id: id, data: msg["data"])
    }
}

extension FxAWebViewController {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let hideLongpress = "document.body.style.webkitTouchCallout='none';"
        webView.evaluateJavaScript(hideLongpress)

        //The helpBrowser shows the current URL in the navbar, the main fxa webview does not.
        guard webView !== helpBrowser else {
            let isSecure = webView.hasOnlySecureContent
            navigationItem.title = (isSecure ? "🔒 " : "") + (webView.url?.host ?? "")
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
