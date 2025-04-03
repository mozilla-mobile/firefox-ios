// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Foundation
import Account
import Shared
import Common
import PDFKit

import enum MozillaAppServices.OAuthScope
import struct MozillaAppServices.FxaAuthData
import struct MozillaAppServices.UserData

enum FxAPageType: Equatable {
    case emailLoginFlow
    case qrCode(url: URL)
    case settingsPage
}

// See https://mozilla.github.io/ecosystem-platform/docs/fxa-engineering/fxa-webchannel-protocol
// For details on message types.
private enum RemoteCommand: String {
     case canLinkAccount = "fxaccounts:can_link_account"
    // case loaded = "fxaccounts:loaded"
    case status = "fxaccounts:fxa_status"
    case oauthLogin = "fxaccounts:oauth_login"
    case login = "fxaccounts:login"
    case changePassword = "fxaccounts:change_password"
    case signOut = "fxaccounts:logout"
    case deleteAccount = "fxaccounts:delete"
    case profileChanged = "profile:change"
}

class FxAWebViewModel: FeatureFlaggable {
    fileprivate let pageType: FxAPageType
    fileprivate let profile: Profile
    fileprivate var deepLinkParams: FxALaunchParams
    fileprivate(set) var baseURL: URL?
    let fxAWebViewTelemetry = FxAWebViewTelemetry()
    private var shouldAskForNotificationPermission: Bool
    private let logger: Logger
    // This is not shown full-screen, use mobile UA
    static let mobileUserAgent = UserAgent.mobileUserAgent()

    var userDefaults: UserDefaultsInterface = UserDefaults.standard

    var blobToDataScript = """
                async function createBlobFromUrl(url) {
                  const response = await fetch(url);
                  const blob = await response.blob();
                  return blob;
                }

                function blobToDataURLAsync(blob) {
                  return new Promise((resolve, reject) => {
                    const reader = new FileReader();
                    reader.onload = () => {
                      resolve(reader.result);
                    };
                    reader.onerror = reject;
                    reader.readAsDataURL(blob);
                  });
                }

                const url = await createBlobFromUrl(blobUrl)
                return await blobToDataURLAsync(url)
            """

    func setupUserScript(for controller: WKUserContentController) {
        guard let path = Bundle.main.path(forResource: "FxASignIn", ofType: "js"),
              let source = try? String(contentsOfFile: path, encoding: .utf8)
        else {
            assertionFailure("Error unwrapping contents of file to set up user script")
            return
        }

        let userScript = WKUserScript(
            source: source,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        controller.addUserScript(userScript)
    }

    /**
     init() FxAWebViewModel.
     - parameter pageType: Specify login flow or settings page if already logged in.
     - parameter profile: a Profile.
     - parameter deepLinkParams: url parameters that originate from a deep link
     - parameter shouldAskForNotificationPermission: indicator if notification permissions should
                                                     be requested from the user upon login.
     */
    required init(pageType: FxAPageType,
                  profile: Profile,
                  deepLinkParams: FxALaunchParams,
                  shouldAskForNotificationPermission: Bool = true,
                  logger: Logger = DefaultLogger.shared) {
        self.pageType = pageType
        self.profile = profile
        self.deepLinkParams = deepLinkParams
        self.shouldAskForNotificationPermission = shouldAskForNotificationPermission
        self.logger = logger
    }

    var onDismissController: (() -> Void)?

    func composeTitle(basedOn url: URL?, hasOnlySecureContent: Bool) -> String {
        return (hasOnlySecureContent ? "🔒 " : "") + (url?.host ?? "")
    }

    func setupFirstPage(completion: @escaping (URLRequest, TelemetryWrapper.EventMethod?) -> Void) {
        if let accountManager = profile.rustFxA.accountManager {
            let entrypoint = self.deepLinkParams.entrypoint.rawValue
            accountManager.getManageAccountURL(entrypoint: "ios_settings_\(entrypoint)") { [weak self] result in
                guard let self = self else { return }

                // Handle authentication with either the QR code login flow, email login flow, or settings page flow
                switch self.pageType {
                case .emailLoginFlow:
                    accountManager.beginAuthentication(
                        entrypoint: "email_\(entrypoint)",
                        scopes: [OAuthScope.profile, OAuthScope.oldSync]
                    ) { [weak self] result in
                        guard let self = self else { return }

                        if case .success(var url) = result {
                            if self.profile.prefs.boolForKey(PrefsKeys.KeyUseReactFxA) ?? false {
                                url = url.withQueryParams([
                                    URLQueryItem(name: "forceExperiment", value: "generalizedReactApp"),
                                    URLQueryItem(name: "forceExperimentGroup", value: "react")
                                ])
                            }
                            self.baseURL = url
                            completion(self.makeRequest(url), .emailLogin)
                        }
                    }
                case let .qrCode(url):
                    self.baseURL = url
                    completion(self.makeRequest(url), .qrPairing)
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
        let args = deepLinkParams.query.filter { $0.key.starts(with: "utm_") }.map {
            return URLQueryItem(name: $0.key, value: $0.value)
        }

        var comp = URLComponents(url: url, resolvingAgainstBaseURL: false)
        comp?.queryItems?.append(contentsOf: args)
        if let url = comp?.url {
            return URLRequest(url: url)
        }

        return URLRequest(url: url)
    }

    func createOutputURL(withFileName name: String, withFileExtension ext: String) -> URL? {
        try? FileManager.default.url(for: .documentDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: false)
        .appendingPathComponent(name)
        .appendingPathExtension(ext)
    }

    func isMozillaAccountPDF(blobURL: URL, webViewURL: URL?) -> Bool {
        if blobURL.scheme == "blob", webViewURL?.host == "accounts.firefox.com" {
            return true
        }
        return false
    }

    func getURLForPDF(webView: WKWebView, blobURL: URL, completion: @escaping (_ outputURL: URL?) -> Void) {
        webView.callAsyncJavaScriptInDefaultContentWorld(
            blobToDataScript,
            arguments: ["blobUrl": blobURL.absoluteString]) { [weak self] result in
                completion(self?.createURLForPDF(result: result))
        }
    }

    func createURLForPDF(result: Result<Any?, Error>) -> URL? {
        switch result {
        case .success(let dataURL):
            guard let data = dataURL as? String,
                  let url = URL(string: data),
                  let data = try? Data(contentsOf: url),
                  let pdf = PDFDocument(data: data),
                  let outputURL = createOutputURL(withFileName: "RecoveryKey",
                                                  withFileExtension: "pdf") else {
                return nil
            }

            pdf.write(to: outputURL)
            if FileManager.default.fileExists(atPath: outputURL.path) {
                let url = URL(fileURLWithPath: outputURL.path)
                return url
            }

            return nil
        case .failure(let error):
            logger.log("Failed to get a valid data URL result, with error: \(error.localizedDescription)",
                       level: .debug,
                       category: .webview)
            return nil
        }
    }
}

// MARK: - Commands
extension FxAWebViewModel {
    func handle(scriptMessage message: WKScriptMessage) {
        guard let url = baseURL,
              let webView = message.webView
        else { return }

        let origin = message.frameInfo.securityOrigin
        guard origin.`protocol` == url.scheme && origin.host == url.host && origin.port == (url.port ?? 0) else {
            logger.log("Ignoring message - \(origin) does not match expected origin: \(url.origin ?? "nil")",
                       level: .warning,
                       category: .sync)
            return
        }

        guard message.name == "accountsCommandHandler" else { return }
        guard let body = message.body as? [String: Any],
              let detail = body["detail"] as? [String: Any],
              let msg = detail["message"] as? [String: Any],
              let cmd = msg["command"] as? String
        else { return }

        let id = Int(msg["messageId"] as? String ?? "")
        handleRemote(command: cmd, id: id, data: msg["data"], webView: webView)
    }

    // Handle a message coming from the content server.
    private func handleRemote(command rawValue: String, id: Int?, data: Any?, webView: WKWebView) {
        if let command = RemoteCommand(rawValue: rawValue) {
            switch command {
            case .oauthLogin:
                if let data = data {
                    onLoginComplete(data: data, webView: webView)
                } else {
                    onDismissController?()
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
                profile.rustFxA.accountManager?.refreshProfile(ignoreCache: true)
                // dismiss keyboard after changing profile in order to see notification view
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            case .login:
                guard let data = data as? [String: Any],
                      let sessionToken = data["sessionToken"] as? String,
                      let email = data["email"] as? String,
                      let uid = data["uid"] as? String,
                      let verified = data["verified"] as? Bool
                else { return }
                let userData = UserData(sessionToken: sessionToken,
                                        uid: uid,
                                        email: email,
                                        verified: verified)
                profile.rustFxA.accountManager?.setUserData(userData: userData) { }
            case .canLinkAccount:
                if let id = id {
                    onCanLinkAccount(msgId: id, webView: webView)
                }
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

        webView.evaluateJavascriptInDefaultContentWorld(msg)
    }

    /// Respond to the webpage session status notification by either passing signed in
    /// user info (for settings), or by passing CWTS setup info (in case the user is
    /// signing up for an account). This latter case is also used for the sign-in state.
    private func onSessionStatus(id: Int, webView: WKWebView) {
        let autofillCreditCardStatus = featureFlags.isFeatureEnabled(.creditCardAutofillStatus, checking: .buildOnly)
        let addressAutofillStatus = AddressLocaleFeatureValidator.isValidRegion()

        let creditCardCapability =  autofillCreditCardStatus ? ", \"creditcards\"" : ""
        let addressAutofillCapability =  addressAutofillStatus ? ", \"addresses\"" : ""

        guard let fxa = profile.rustFxA.accountManager else { return }
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
                        { choose_what_to_sync: true, engines: ["bookmarks", "history", "tabs", "passwords"\(creditCardCapability)\(addressAutofillCapability)] },
                    }
                """
        }

        runJS(webView: webView, typeId: typeId, messageId: id, command: cmd, data: data)
    }

    private func onLoginComplete(data: Any, webView: WKWebView) {
        guard let data = data as? [String: Any],
              let code = data["code"] as? String,
              let state = data["state"] as? String
        else { return }

        if let declinedSyncEngines = data["declinedSyncEngines"] as? [String] {
            // Stash the declined engines so on first sync we can disable them!
            UserDefaults.standard.set(declinedSyncEngines, forKey: "fxa.cwts.declinedSyncEngines")
        }

        let auth = FxaAuthData(code: code, state: state, actionQueryParam: "signin")
        profile.rustFxA.accountManager?.finishAuthentication(authData: auth) { _ in
            self.profile.syncManager?.onAddedAccount()

            // only ask for notification permission if it's not onboarding related (e.g. settings)
            // or if the onboarding flow is missing the notifications card
            guard self.shouldAskForNotificationPermission else { return }

            NotificationManager().requestAuthorization { granted, error in
                guard error == nil else { return }
                if granted {
                    if self.userDefaults.object(forKey: PrefsKeys.Notifications.SyncNotifications) == nil {
                        self.userDefaults.set(granted, forKey: PrefsKeys.Notifications.SyncNotifications)
                    }
                    if self.userDefaults.object(forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications) == nil {
                        self.userDefaults.set(granted, forKey: PrefsKeys.Notifications.TipsAndFeaturesNotifications)
                    }
                    NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
                }
            }
        }
        // Record login or registration completed telemetry
        fxAWebViewTelemetry.recordTelemetry(for: .completed)
        onDismissController?()
    }

    private func onPasswordChange(data: Any, webView: WKWebView) {
        guard let data = data as? [String: Any],
              let sessionToken = data["sessionToken"] as? String
        else { return }

        profile.rustFxA.accountManager?.handlePasswordChanged(newSessionToken: sessionToken) { [weak self] in
            NotificationCenter.default.post(name: .RegisterForPushNotifications, object: nil)
            self?.profile.syncManager?.syncEverything(why: .enabledChange)
        }
    }

    private func onCanLinkAccount(msgId: Int, webView: WKWebView) {
        let cmd = RemoteCommand.canLinkAccount.rawValue
        let typeId = "account_updates"
        // Respond with an 'ok' message immediately today so FxA does not need to support conditional logic on the
        // server-side just for iOS.
        // For proper account merging support, see: https://github.com/mozilla-mobile/firefox-ios/issues/21873
        let data = """
            { "ok": true }
        """

        runJS(webView: webView, typeId: typeId, messageId: msgId, command: cmd, data: data)
    }

    func shouldAllowRedirectAfterLogIn(basedOn navigationURL: URL?) -> WKNavigationActionPolicy {
        // Cancel navigation that happens after login to an account, which is when a redirect to `redirectURL` happens.
        // The app handles this event fully in native UI.
        let redirectUrl = RustFirefoxAccounts.redirectURL
        if let navigationURL = navigationURL {
            let expectedRedirectURL = URL(string: redirectUrl, invalidCharacters: false)!
            if navigationURL.scheme == expectedRedirectURL.scheme
                && navigationURL.host == expectedRedirectURL.host
                && navigationURL.path == expectedRedirectURL.path {
                return .cancel
            }
        }
        return .allow
    }
}
