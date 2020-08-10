/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import Foundation
import Account
import MozillaAppServices
import Shared
import SwiftKeychainWrapper

enum FxAPageType {
    case emailLoginFlow
    case qrCode(url: String)
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

class FxAWebViewModel {
    fileprivate let pageType: FxAPageType
    fileprivate let profile: Profile
    fileprivate var deepLinkParams: FxALaunchParams?
    fileprivate(set) var baseURL: URL?

    // This is not shown full-screen, use mobile UA
    static let mobileUserAgent = UserAgent.mobileUserAgent()

    func setupUserScript(for controller: WKUserContentController) {
        guard let path = Bundle.main.path(forResource: "FxASignIn", ofType: "js"), let source = try? String(contentsOfFile: path, encoding: .utf8) else {
            assert(false)
            return
        }
        let userScript = WKUserScript(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        controller.addUserScript(userScript)
    }

    /**
    init() FxAWebViewModel.
    - parameter pageType: Specify login flow or settings page if already logged in.
    - parameter profile: a Profile.
    - parameter deepLinkParams: url parameters that originate from a deep link
    */
    required init(pageType: FxAPageType, profile: Profile, deepLinkParams: FxALaunchParams?) {
        self.pageType = pageType
        self.profile = profile
        self.deepLinkParams = deepLinkParams

        // If accountMigrationFailed then the app menu has a caution icon,
        // and at this point the user has taken sufficient action to clear the caution.
        profile.rustFxA.accountMigrationFailed = false
    }

    var onDismissController: (() -> Void)?
    
    func composeTitle(basedOn url: URL?, hasOnlySecureContent: Bool) -> String {
        return (hasOnlySecureContent ? "🔒 " : "") + (url?.host ?? "")
    }

    func setupFirstPage(completion: @escaping ((URLRequest, TelemetryWrapper.EventMethod?) -> Void)) {
        profile.rustFxA.accountManager.uponQueue(.main) { accountManager in
            accountManager.getManageAccountURL(entrypoint: "ios_settings_manage") { [weak self] result in
                guard let self = self else { return }

                // Handle authentication with either the QR code login flow, email login flow, or settings page flow
                switch self.pageType {
                case .emailLoginFlow:
                    accountManager.beginAuthentication { [weak self] result in
                        guard let self = self else { return }

                        if case .success(let url) = result {
                            self.baseURL = url
                            completion(self.makeRequest(url), .emailLogin)
                        }
                    }
                case let .qrCode(url):
                    accountManager.beginPairingAuthentication(pairingUrl: url) { [weak self] result in
                        guard let self = self else { return }

                        if case .success(let url) = result {
                            self.baseURL = url
                            completion(self.makeRequest(url), .qrPairing)
                        }
                    }
                case .settingsPage:
                    if case .success(let url) = result {
                        self.baseURL = url
                        completion(self.makeRequest(url), nil)
                    }
                }
            }
        }
    }
    
    private func makeRequest(_ url: URL) -> URLRequest {
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
}

// MARK: - Commands
extension FxAWebViewModel {
    func handle(scriptMessage message: WKScriptMessage) {
        guard let url = baseURL, let webView = message.webView else { return }
        
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
        handleRemote(command: cmd, id: id, data: msg["data"], webView: webView)
    }
    
    // Handle a message coming from the content server.
    private func handleRemote(command rawValue: String, id: Int?, data: Any?, webView: WKWebView) {
        if let command = RemoteCommand(rawValue: rawValue) {
            switch command {
            case .login:
                if let data = data {
                    onLogin(data: data, webView: webView)
                }
            case .changePassword:
                if let data = data {
                    onPasswordChange(data: data, webView: webView)
                }
            case .status:
                if let id = id {
                    onSessionStatus(id: id, webView: webView)
                }
            case .deleteAccount, .signOut:
                profile.removeAccount()
                onDismissController?()
            case .profileChanged:
                profile.rustFxA.accountManager.peek()?.refreshProfile(ignoreCache: true)
                // dismiss keyboard after changing profile in order to see notification view
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }

    /// Send a message to web content using the required message structure.
    private func runJS(webView: WKWebView, typeId: String, messageId: Int, command: String, data: String = "{}") {
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
    private func onSessionStatus(id: Int, webView: WKWebView) {
        guard let fxa = profile.rustFxA.accountManager.peek() else { return }
        let cmd = "fxaccounts:fxa_status"
        let typeId = "account_updates"
        let data: String
        switch pageType {
            case .settingsPage:
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
            case .emailLoginFlow, .qrCode:
                data = """
                    { capabilities:
                        { choose_what_to_sync: true, engines: ["bookmarks", "history", "tabs", "passwords"] },
                    }
                """
        }

        runJS(webView: webView, typeId: typeId, messageId: id, command: cmd, data: data)
    }

    private func onLogin(data: Any, webView: WKWebView) {
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
        profile.rustFxA.accountManager.peek()?.finishAuthentication(authData: auth) { _ in
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
        
        onDismissController?()
    }
    
    private func onPasswordChange(data: Any, webView: WKWebView) {
        guard let data = data as? [String: Any], let sessionToken = data["sessionToken"] as? String else {
            return
        }
        
        profile.rustFxA.accountManager.peek()?.handlePasswordChanged(newSessionToken: sessionToken) {
            NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
        }
    }
    
    func shouldAllowRedirectAfterLogIn(basedOn navigationURL: URL?) -> WKNavigationActionPolicy {
        // Cancel navigation that happens after login to an account, which is when a redirect to `redirectURL` happens.
        // The app handles this event fully in native UI.
        let redirectUrl = RustFirefoxAccounts.redirectURL
        if let navigationURL = navigationURL {
            let expectedRedirectURL = URL(string: redirectUrl)!
            if navigationURL.scheme == expectedRedirectURL.scheme && navigationURL.host == expectedRedirectURL.host && navigationURL.path == expectedRedirectURL.path {
                return .cancel
            }
        }
        return .allow
    }
}
