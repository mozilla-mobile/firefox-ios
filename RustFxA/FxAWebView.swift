/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import Account
import MozillaAppServices

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
    //case changePassword = "change_password"
    //case signOut = "sign_out"
    //case deleteAccount = "delete_account"
}

class FxAWebView: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView
    var dismissType: DismissType = .dismiss
    let pageType: FxAPageType
    fileprivate var baseURL: URL?
    let settingsURL = "https://accounts.firefox.com/settings?service=sync&context=oauth_webchannel_v1"

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

        super.init(nibName: nil, bundle: nil)
        contentController.add(self, name: "accountsCommandHandler")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
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

    private func matchingRedirectURLReceived(components: URLComponents) {
        var dic = [String: String]()
        components.queryItems?.forEach { dic[$0.name] = $0.value }
        let data = FxaAuthData(code: dic["code"]!, state: dic["state"]!, actionQueryParam: "signin")
        RustFirefoxAccounts.shared.accountManager.finishAuthentication(authData: data) { _ in
            let application = UIApplication.shared
            // ask for push notification
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                DispatchQueue.main.async {
                    guard error == nil else {
                        return
                    }
                    if granted {
                        application.registerForRemoteNotifications()
                    }
                }
            }
        }

        if dismissType == .dismiss {
            dismiss(animated: true)
        } else {
            navigationController?.popToRootViewController(animated: true)
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        let redirectUrl = RustFirefoxAccounts.shared.redirectURL
        if let navigationURL = navigationAction.request.url {
            let expectedRedirectURL = URL(string: redirectUrl)!
            if navigationURL.scheme == expectedRedirectURL.scheme && navigationURL.host == expectedRedirectURL.host && navigationURL.path == expectedRedirectURL.path,
                let components = URLComponents(url: navigationURL, resolvingAgainstBaseURL: true) {
                matchingRedirectURLReceived(components: components)
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
            case .status:
                if let id = id {
                    onSessionStatus(id: id)
                }
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

        let auth = FxaAuthData(code: code, state: state, actionQueryParam: "signin")
        RustFirefoxAccounts.shared.accountManager.finishAuthentication(authData: auth) { _ in
            let application = UIApplication.shared
            // ask for push notification
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                DispatchQueue.main.async {
                    guard error == nil else {
                        return
                    }
                    if granted {
                        application.registerForRemoteNotifications()
                    }
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
