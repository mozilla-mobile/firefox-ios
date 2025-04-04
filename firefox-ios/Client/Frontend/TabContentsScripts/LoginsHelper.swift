// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage
import WebKit

import struct MozillaAppServices.LoginEntry

enum FocusFieldType: String, Codable {
    case username
    case password
}

struct FieldFocusMessage: Codable {
    let fieldType: FocusFieldType
    let type: String
}

struct LoginInjectionData: Codable {
    var requestId: String
    var name = "RemoteLogins:loginsFound"
    var logins: [LoginItem]
}

struct LoginItem: Codable {
    var username: String
    var password: String
    var hostname: String
}

class LoginsHelper: TabContentScript, FeatureFlaggable {
    private weak var tab: Tab?
    private let profile: Profile
    private let theme: Theme
    private var loginAlert: SaveLoginAlert?
    private var loginAlertTimer: Timer?
    private var loginAlertTimeout: TimeInterval = 10
    private var currentRequestId = ""
    private var logger: Logger = DefaultLogger.shared

    public var foundFieldValues: ((FocusFieldType, String) -> Void)?

    public var passwordFieldInteraction: (() -> Void)?

    // Exposed for mocking purposes
    var logins: RustLogins {
        return profile.logins
    }

    class func name() -> String {
        String(describing: self)
    }

    required init(tab: Tab,
                  profile: Profile,
                  theme: Theme) {
        self.tab = tab
        self.profile = profile
        self.theme = theme
    }

    func prepareForDeinit() {
        self.loginAlertTimer = nil
        if let loginAlert {
            self.loginAlert = nil
            tab?.removeLoginAlert(loginAlert)
        }
    }

    func scriptMessageHandlerNames() -> [String]? {
        return ["loginsManagerMessageHandler"]
    }

    private func getOrigin(_ uriString: String, allowJS: Bool = false) -> String? {
        guard let uri = URL(string: uriString, invalidCharacters: false),
              let scheme = uri.scheme, !scheme.isEmpty,
              let host = uri.host
        else {
            // bug 159484 - disallow url types that don't support a hostPort.
            // (although we handle "javascript:..." as a special case above.)
            return nil
        }

        if allowJS && scheme == "javascript" {
            return "javascript:"
        }

        var realm = "\(scheme)://\(host)"

        // If the URI explicitly specified a port, only include it when
        // it's not the default. (We never want "http://foo.com:80")
        if let port = uri.port {
            realm += ":\(port)"
        }

        return realm
    }

    func loginRecordFromScript(_ script: [String: Any], url: URL) -> LoginEntry? {
        guard let username = script["username"] as? String,
              let password = script["password"] as? String,
              let origin = getOrigin(url.absoluteString)
        else { return nil }

        var dict: [String: Any] = [
            "hostname": origin,
            "username": username,
            "password": password
        ]

        if let string = script["formSubmitUrl"] as? String,
            let formSubmitUrl = getOrigin(string) {
            dict["formSubmitUrl"] = formSubmitUrl
        }

        if let passwordField = script["passwordField"] as? String {
            dict["passwordField"] = passwordField
        }

        if let usernameField = script["usernameField"] as? String {
            dict["usernameField"] = usernameField
        }

        return LoginEntry(fromJSONDict: dict)
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        guard let res = message.body as? [String: Any],
              let type = res["type"] as? String
        else { return }

        if type == "clearAccessoryView" {
            tab?.webView?.accessoryView.reloadViewFor(.standard)
        }

        if type == "generatePassword",
            let tab = self.tab,
            !tab.isPrivate,
            profile.prefs.boolForKey("saveLogins") ?? true {
            let userDefaults = UserDefaults.standard
            let showPasswordGeneratorClosure = {
                let newAction = GeneralBrowserAction(
                    frame: message.frameInfo,
                    windowUUID: tab.windowUUID,
                    actionType: GeneralBrowserActionType.showPasswordGenerator)

                store.dispatch(newAction)
            }
            if userDefaults.value(forKey: PrefsKeys.PasswordGeneratorShown) == nil {
                userDefaults.set(true, forKey: PrefsKeys.PasswordGeneratorShown)
                showPasswordGeneratorClosure()
            } else {
                tab.webView?.accessoryView.useStrongPasswordClosure = showPasswordGeneratorClosure
                tab.webView?.accessoryView.reloadViewFor(.passwordGenerator)
            }
        }

        // NOTE: FXIOS-3856 will further enhance the logs into actual callback
        if let parsedMessage = parseFieldFocusMessage(from: res) {
            logger.log("Parsed message \(String(describing: parsedMessage))",
                       level: .debug,
                       category: .webview)
            sendMessageType(parsedMessage)
        }

        // We don't use the WKWebView's URL since the page can spoof the URL by using document.location
        // right before requesting login data. See bug 1194567 for more context.
        if let url = message.frameInfo.request.url {
            // Since responses go to the main frame, make sure we only listen for main frame requests
            // to avoid XSS attacks.
            if message.frameInfo.isMainFrame && type == "request" {
                requestLogins(res, url: url)
            } else if type == "submit" {
                if profile.prefs.boolForKey("saveLogins") ?? true {
                    if let login = loginRecordFromScript(res, url: url) {
                        setCredentials(login)
                    }
                }
            }
        }
    }

    private func sendMessageType(_ message: FieldFocusMessage) {
        // NOTE: This is a partial stub / placeholder
        // FXIOS-3856 will further enhance the logs into actual callback
        switch message.fieldType {
        case .username:
            logger.log("Parsed message username",
                       level: .debug,
                       category: .webview)
        case .password:
            logger.log("Parsed message password",
                       level: .debug,
                       category: .webview)
        }
        foundFieldValues?(message.fieldType, currentRequestId)
    }

    private func parseFieldFocusMessage(from dictionary: [String: Any]) -> FieldFocusMessage? {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            let message = try JSONDecoder().decode(FieldFocusMessage.self, from: data)
            return message
        } catch {
            logger.log("Unable to decode message body in logins helper",
                       level: .warning,
                       category: .webview)
            return nil
        }
    }

    func setCredentials(_ login: LoginEntry) {
        if login.password.isEmpty || login.username.isEmpty {
            return
        }

        profile.logins.getLoginsFor(
            protectionSpace: login.protectionSpace,
            withUsername: login.username
        ) { res in
            DispatchQueue.main.async {
                switch res {
                case .success(let successValue):
                    for saved in successValue {
                        if saved.password == login.password {
                            self.profile.logins.use(login: saved, completionHandler: { _ in })
                            return
                        }

                        self.promptUpdateFromLogin(login: saved, toLogin: login)
                        return
                    }
                case .failure:
                    break
                }

                self.promptSave(login)
            }
        }
    }

    private func promptSave(_ login: LoginEntry) {
        guard login.isValid.isSuccess else { return }

        if profile.prefs.boolForKey("saveLogins") ?? true &&
            tab?.isPrivate == false {
            clearStoredPasswordAfterGeneration(origin: login.hostname)
        }

        let promptMessage: String
        let https = "^https:\\/\\/"
        let url = login.hostname.replacingOccurrences(of: https, with: "", options: .regularExpression, range: nil)

        let userName = login.username
        if !userName.isEmpty {
            promptMessage = String(format: .SaveLoginUsernamePrompt, userName, url)
        } else {
            promptMessage = String(format: .SaveLoginPrompt, url)
        }

        if let existingPrompt = self.loginAlert {
            tab?.removeLoginAlert(existingPrompt)
        }

        let alert = SaveLoginAlert()
        alert.saveAction = {
            self.tab?.removeLoginAlert(alert)
            self.loginAlert = nil
            self.sendLoginsSavedTelemetry()
            self.profile.logins.addLogin(login: login, completionHandler: { _ in })
        }
        alert.notNotAction = {
            self.tab?.removeLoginAlert(alert)
            self.loginAlert = nil
        }

        let viewModel = SaveLoginAlertViewModel(
            saveButtonTitle: .LoginsHelperSaveLoginButtonTitle,
            saveButtonA11yId: AccessibilityIdentifiers.SaveLoginAlert.saveButton,
            notNowButtonTitle: .LoginsHelperDontSaveButtonTitle,
            notNowButtonA11yId: AccessibilityIdentifiers.SaveLoginAlert.notNowButton,
            titleText: promptMessage
        )
        alert.configure(viewModel: viewModel)

        show(alert)
    }

    private func promptUpdateFromLogin(login old: LoginRecord, toLogin new: LoginEntry) {
        guard new.isValid.isSuccess else { return }

        let formatted: String
        let userName = new.username
        if !userName.isEmpty {
            formatted = String(format: .UpdateLoginUsernamePrompt, userName, new.hostname)
        } else {
            formatted = String(format: .UpdateLoginPrompt, new.hostname)
        }

        if let existingPrompt = self.loginAlert {
            tab?.removeLoginAlert(existingPrompt)
        }

        let alert = SaveLoginAlert()
        alert.saveAction = {
            self.tab?.removeLoginAlert(alert)
            self.loginAlert = nil
            self.sendLoginsModifiedTelemetry()
            self.profile.logins.updateLogin(id: old.id, login: new, completionHandler: { _ in })
        }
        alert.notNotAction = {
            self.tab?.removeLoginAlert(alert)
            self.loginAlert = nil
        }

        let viewModel = SaveLoginAlertViewModel(
            saveButtonTitle: .LoginsHelperUpdateButtonTitle,
            saveButtonA11yId: AccessibilityIdentifiers.SaveLoginAlert.updateButton,
            notNowButtonTitle: .LoginsHelperDontUpdateButtonTitle,
            notNowButtonA11yId: AccessibilityIdentifiers.SaveLoginAlert.dontUpdateButton,
            titleText: formatted
        )
        alert.configure(viewModel: viewModel)

        show(alert)
    }

    private func show(_ alert: SaveLoginAlert) {
        loginAlert = alert
        loginAlert?.applyTheme(theme: theme)
        tab?.addLoginAlert(alert)

        let timer = Timer(
            timeInterval: loginAlertTimeout,
            target: self,
            selector: #selector(timerDone),
            userInfo: nil,
            repeats: false
        )
        RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
        loginAlert?.shouldPersist = true
        loginAlertTimer = timer
    }

    @objc
    func timerDone() {
        loginAlert?.shouldPersist = false
        loginAlertTimer = nil
    }

    private func requestLogins(_ request: [String: Any], url: URL) {
        guard let requestId = request["requestId"] as? String,
            // Even though we don't currently use these two fields,
            // verify that they were received as additional confirmation
            // that this is a valid request from LoginsHelper.js.
            request["formOrigin"] as? String != nil,
            request["actionOrigin"] as? String != nil
        else { return }

        currentRequestId = requestId
    }

    private func clearStoredPasswordAfterGeneration(origin: String) {
        if let windowUUID = self.tab?.windowUUID {
            let action = PasswordGeneratorAction(windowUUID: windowUUID,
                                                 actionType: PasswordGeneratorActionType.clearGeneratedPasswordForSite,
                                                 origin: origin)
            store.dispatch(action)
        }
    }

    public static func fillLoginDetails(with tab: Tab,
                                        loginData: LoginInjectionData) {
        guard let data = try? JSONEncoder().encode(loginData),
              let injected = String(data: data, encoding: .utf8)
        else { return }
        let injectJavaScript = "window.__firefox__.logins.inject(\(injected))"
        tab.webView?.evaluateJavascriptInDefaultContentWorld(injectJavaScript)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .loginsAutofilled)
    }

    public static func yieldFocusBackToField(with tab: Tab) {
        let jsFocusCallback = "window.__firefox__.logins.yieldFocusBackToField()"
        tab.webView?.evaluateJavascriptInDefaultContentWorld(jsFocusCallback)
    }

    // MARK: Theming System
    private func applyTheme(for views: UIView...) {
        views.forEach { view in
            if let view = view as? ThemeApplicable {
                view.applyTheme(theme: theme)
            }
        }
    }

    // MARK: - Telemetry
    private func sendLoginsModifiedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .change,
                                     object: .loginsModified)
    }

    private func sendLoginsSavedTelemetry() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .add,
                                     object: .loginsSaved)
    }
}
