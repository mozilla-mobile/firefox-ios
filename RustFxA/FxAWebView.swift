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
    case signUpFlow
    case settingsPage
}

// See https://mozilla.github.io/ecosystem-platform/docs/fxa-engineering/fxa-webchannel-protocol
// For details on message types.
fileprivate enum RemoteCommand: String {
    //case canLinkAccount = "can_link_account"
    // case loaded = "fxaccounts:loaded"
    case status = "fxaccounts:fxa_status"
    case login = "fxaccounts:oauth_login"
    case changePassword = "fxaccounts:change_password"
    case signOut = "fxaccounts:logout"
    case deleteAccount = "fxaccounts:delete_account"
    case profileChanged = "profile:change"
}

/**
 Show the FxA web content for signing in, signing up, or showing FxA settings.
 Messaging from the website to native is with WKScriptMessageHandler.
 */
class FxAWebView: UIViewController, WKNavigationDelegate {
    fileprivate let dismissType: DismissType
    fileprivate var webView: WKWebView
    fileprivate let pageType: FxAPageType
    fileprivate var baseURL: URL?
    fileprivate let profile: Profile

    /// Used to show a second WKWebView to browse help links.
    fileprivate var helpBrowser: WKWebView?

    /**
     init() FxAWebView.

     - parameter pageType: Specify login flow or settings page if already logged in.
     - parameter profile: a Profile.
     - parameter dismissalStyle: depending on how this was presented, it uses modal dismissal, or if part of a UINavigationController stack it will pop to the root.
     */
    init(pageType: FxAPageType, profile: Profile, dismissalStyle: DismissType) {
        self.pageType = pageType
        self.profile = profile
        self.dismissType = dismissalStyle

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
        // If accountMigrationFailed then the app menu has a caution icon, and at this point the user has taken sufficient action to clear the caution.
        RustFirefoxAccounts.shared.accountMigrationFailed = false

        super.viewDidLoad()
        webView.navigationDelegate = self
        view = webView

        RustFirefoxAccounts.shared.accountManager.uponQueue(.main) { accountManager in
            accountManager.getManageAccountURL(entrypoint: "ios_settings_manage") { [weak self] result in
                guard let self = self else { return }

                // Either show the settings, or the authentication flow.

                if self.pageType == .settingsPage, case .success(let url) = result {
                    self.baseURL = url
                    self.webView.load(URLRequest(url: url))
                } else {
                    accountManager.beginAuthentication() { [weak self] result in
                        if case .success(let url) = result {
                            self?.baseURL = url
                            self?.webView.load(URLRequest(url: url))
                        }
                    }
                }
            }
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

extension FxAWebView: WKScriptMessageHandler {
    // Handle a message coming from the content server.
    private func handleRemote(command rawValue: String, id: Int?, data: Any?) {
        if let command = RemoteCommand(rawValue: rawValue) {
            switch command {
            case .login:
                if let data = data {
                    onLogin(data: data)
                }
            case .changePassword:
                if let data = data {
                    onPasswordChange(data: data)
                }
            case .status:
                if let id = id {
                    onSessionStatus(id: id)
                }
            case .deleteAccount, .signOut:
                profile.removeAccount()
                dismiss(animated: true)
            case .profileChanged:
                RustFirefoxAccounts.shared.accountManager.peek()?.refreshProfile(ignoreCache: true)
            }
        }
    }

    /// Send a message to web content using the required message structure.
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

    /// Respond to the webpage session status notification by either passing signed in user info (for settings), or by passing CWTS setup info (in case the user is signing up for an account). This latter case is also used for the sign-in state.
    private func onSessionStatus(id: Int) {
        guard let fxa = RustFirefoxAccounts.shared.accountManager.peek() else { return }
        let cmd = "fxaccounts:fxa_status"
        let typeId = "account_updates"
        let data: String
        if pageType == .settingsPage {
            // Both email and uid are required at this time to properly link the FxA settings session
            let email = fxa.accountProfile()?.email ?? ""
            let uid = fxa.accountProfile()?.uid ?? ""
            let token = (try? fxa.getSessionToken().get()) ?? ""
            data = """
            {
                capabilities: {},
                signedInUser: {
                    sessionToken: "\(token)",
                    email: "\(email)",
                    uid: "\(uid)",
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

        // Use presence of key `offeredSyncEngines` to determine if this was a new sign-up.
        if let engines = data["offeredSyncEngines"] as? [String], engines.count > 0 {
            LeanPlumClient.shared.track(event: .signsUpFxa)
        } else {
            LeanPlumClient.shared.track(event: .signsInFxa)
        }
        LeanPlumClient.shared.set(attributes: [LPAttributeKey.signedInSync: true])

        let auth = FxaAuthData(code: code, state: state, actionQueryParam: "signin")
        RustFirefoxAccounts.shared.accountManager.peek()?.finishAuthentication(authData: auth) { _ in
            self.profile.syncManager.onAddedAccount()
            
            // ask for push notification
            KeychainWrapper.sharedAppContainerKeychain.removeObject(forKey: KeychainKey.apnsToken, withAccessibility: .afterFirstUnlock)
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

        dismiss(animated: true)
    }

    private func onPasswordChange(data: Any) {
        guard let data = data as? [String: Any], let sessionToken = data["sessionToken"] as? String else {
            return
        }

        RustFirefoxAccounts.shared.accountManager.peek()?.handlePasswordChanged(newSessionToken: sessionToken) {
            NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
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

extension FxAWebView {
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

extension FxAWebView: WKUIDelegate {
    
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
