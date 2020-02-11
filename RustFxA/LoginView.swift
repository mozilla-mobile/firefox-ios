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

enum FxALoginFlow {
    case emailLoginFlow
    case signUpFlow
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

class RustLoginView: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView
    var dismissType: DismissType = .dismiss
    let fxaLaunchParams: FxALaunchParams
    let loginFlowType: FxALoginFlow
    fileprivate var baseURL: URL?

    init(fxaOptions: FxALaunchParams?, flowType: FxALoginFlow) {
        self.fxaLaunchParams = fxaOptions ?? FxALaunchParams(query: [String: String]())
        self.loginFlowType = flowType

        let contentController = WKUserContentController()
        if let path = Bundle.main.path(forResource: "FxASignIn", ofType: "js") {
            if let source = try? String(contentsOfFile: path, encoding: .utf8) {
                let userScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
                contentController.addUserScript(userScript)
            }
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
        self.webView.navigationDelegate = self
        self.view = self.webView

        RustFirefoxAccounts.shared.accountManager.beginAuthentication() { [weak self] result in
            if case .success(let url) = result {
                self?.baseURL = url
                self?.webView.load(URLRequest(url: url))
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

extension RustLoginView: WKScriptMessageHandler {
    // Handle a message coming from the content server.
    private func handleRemote(command rawValue: String, id: Int?, data: Any?) {
        if let command = RemoteCommand(rawValue: rawValue) {
            switch command {
            case .login:
                onLogin(data: data)
            case .status:
                if let id = id {
                    onSessionStatus(id: id)
                }
            }
        }
    }

    private func runJS(typeId: String, messageId: Int, command: String) {
        let msg = """
            var msg = {
                id: "\(typeId)",
                message: {
                    messageId: \(messageId),
                    command: "\(command)",
                    data : {}
                }
            };
            window.dispatchEvent(new CustomEvent('WebChannelMessageToContent', { detail: JSON.stringify(msg) }));
        """

        webView.evaluateJavaScript(msg)
    }

    private func onSessionStatus(id: Int) {
        let cmd = "fxaccounts:fxa_status"
        let typeId = "account_updates"
        runJS(typeId: typeId, messageId: id, command: cmd)
    }

    private func onLogin(data: Any) {
        guard let data = data as? [String: Any], let code = data["code"] as? String, let state = data["state"] as? String else {
            return
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
