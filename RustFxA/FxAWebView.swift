/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import Account
import MozillaAppServices
import Shared

enum DismissType {
    case dismiss
    case popToRootVC
}

enum FxAPageType {
    case emailLoginFlow
    case signUpFlow
    case settingsPage
}

fileprivate enum RemoteCommand: String {
    //case canLinkAccount = "can_link_account"
    // case loaded = "fxaccounts:loaded"
    case status = "fxaccounts:fxa_status"
    case login = "fxaccounts:oauth_login"
    case changePassword = "fxaccounts:change_password"
    //case signOut = "sign_out"
    case deleteAccount = "fxaccounts:delete_account"
}

class FxAWebView: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView
    var dismissType: DismissType = .dismiss
    let pageType: FxAPageType
    fileprivate var baseURL: URL?
    let settingsURL = "https://accounts.firefox.com/settings?service=sync&context=oauth_webchannel_v1"
    private var helpBrowser: WKWebView?

    init(pageType: FxAPageType) {
        self.pageType = pageType

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
        // If accountMigrationFailed then the app menu has a caution icon, and at this point the user has taken
        // sufficient action to clear the caution.
        RustFirefoxAccounts.shared.accountMigrationFailed = false

        super.viewDidLoad()
        webView.navigationDelegate = self
        view = webView

        if pageType == .settingsPage, let url = URL(string: settingsURL) {
            baseURL = url
            webView.load(URLRequest(url: url))
        } else {
            RustFirefoxAccounts.shared.accountManager.beginAuthentication() { [weak self] result in
                if case .success(let url) = result {
                    self?.baseURL = url
                    self?.webView.load(URLRequest(url: url))
                }
            }
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        let redirectUrl = RustFirefoxAccounts.shared.redirectURL
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

extension FxAWebView: WKScriptMessageHandler {
    // Handle a message coming from the content server.
    private func handleRemote(command rawValue: String, id: Int?, data: Any?) {
        if let command = RemoteCommand(rawValue: rawValue) {
            switch command {
            case .login, .changePassword:
                if let data = data {
                    onLogin(data: data)
                }
            case .status:
                if let id = id {
                    onSessionStatus(id: id)
                }
            case .deleteAccount:
                FxALoginHelper.sharedInstance.disconnect()
                dismiss(animated: true)
            }
        }
    }

    private func runJS(typeId: String, messageId: Int, command: String, data: String = "{}") {
        let msg = """
            var msg = {
                id: "\(typeId)",
                message: {
                    messageId: \(messageId),
                    command: "\(command)",
                    data : \(data)
                }
            };
            window.dispatchEvent(new CustomEvent('WebChannelMessageToContent', { detail: JSON.stringify(msg) }));
        """

        webView.evaluateJavaScript(msg)
    }

    private func onSessionStatus(id: Int) {
        let cmd = "fxaccounts:fxa_status"
        let typeId = "account_updates"
        let data: String
        if pageType == .settingsPage {
            let fxa = RustFirefoxAccounts.shared.accountManager
            let email = fxa.accountProfile()?.email ?? ""
            let token = (try? fxa.getSessionToken().get()) ?? ""
            data = """
            {   signedInUser: {
                    sessionToken: "\(token)",
                    email: "\(email)",
                    verified: true,
                }
            }
        """
        } else {
            data = """
                { capabilities:
                    { choose_what_to_sync: true, engines: ["bookmarks", "history", "tabs", "passwords"] },
                }
            """
        }

        runJS(typeId: typeId, messageId: id, command: cmd, data: data)
    }

    private func onLogin(data: Any) {
        guard let data = data as? [String: Any], let code = data["code"] as? String, let state = data["state"] as? String else {
            return
        }

        if let declinedSyncEngines = data["declinedSyncEngines"] as? [String] {
            // Stash the declined engines so on first sync we can disable them!
            UserDefaults.standard.set(declinedSyncEngines, forKey: "fxa.cwts.declinedSyncEngines")
        }

        if let engines = data["offeredSyncEngines"] as? [String], engines.count > 0 {
            LeanPlumClient.shared.track(event: .signsUpFxa)
        } else {
            LeanPlumClient.shared.track(event: .signsInFxa)
        }
        LeanPlumClient.shared.set(attributes: [LPAttributeKey.signedInSync: true])

        let auth = FxaAuthData(code: code, state: state, actionQueryParam: "signin")
        RustFirefoxAccounts.shared.accountManager.finishAuthentication(authData: auth) { _ in
            // ask for push notification
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                guard error == nil else {
                    return
                }
                if granted {
                    NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
                }
            }
        }

        if dismissType == .dismiss {
            dismiss(animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }


    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let url = baseURL else { return }

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
        handleRemote(command: cmd, id: id, data: msg["data"])
    }
}

extension FxAWebView{
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let hideLongpress = "document.body.style.webkitTouchCallout='none';"
        webView.evaluateJavaScript(hideLongpress)
        guard webView !== helpBrowser else {
            let isSecure = webView.hasOnlySecureContent
            navigationItem.title = (isSecure ? "🔒 " : "") + (webView.url?.host ?? "")
            return
        }

        navigationItem.title = nil
    }
}

extension FxAWebView: WKUIDelegate {
    // Blank target links (support  links) will create a 2nd webview to browse.
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
