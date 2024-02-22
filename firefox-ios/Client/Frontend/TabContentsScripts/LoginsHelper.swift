// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage
import WebKit

enum FocusFieldType: String, Codable {
    case username
    case password
}

struct FieldFocusMessage: Codable {
    let fieldType: FocusFieldType
    let type: String
}

struct LoginInjectionData {
    let requestId: String
    let name: String = "RemoteLogins:loginsFound"
    var logins: [[String: Any]]

    func toJSONString() -> String? {
        let dict: [String: Any] = [
            "requestId": requestId,
            "name": name,
            "logins": logins
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}

class LoginsHelper: TabContentScript {
    private weak var tab: Tab?
    private let profile: Profile
    private let theme: Theme
    private var snackBar: SnackBar?
    private var currentRequestId: String = ""
    private var logger: Logger = DefaultLogger.shared

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

    class func replace(_ base: String, keys: [String], replacements: [String]) -> NSMutableAttributedString {
        var ranges = [NSRange]()
        var string = base
        for (index, key) in keys.enumerated() {
            let replace = replacements[index]
            let range = string.range(of: key,
                                     options: .literal,
                                     range: nil,
                                     locale: nil)!
            string.replaceSubrange(range, with: replace)
            let nsRange = NSRange(location: string.distance(from: string.startIndex, to: range.lowerBound),
                                  length: replace.count)
            ranges.append(nsRange)
        }

        var attributes = [NSAttributedString.Key: AnyObject]()
        attributes[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        attributes[NSAttributedString.Key.foregroundColor] = UIColor.Photon.Grey60
        let attr = NSMutableAttributedString(string: string, attributes: attributes)
        let font = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.medium)
        for range in ranges {
            attr.addAttribute(NSAttributedString.Key.font, value: font, range: range)
        }
        return attr
    }

    func setCredentials(_ login: LoginEntry) {
        if login.password.isEmpty {
            return
        }

        profile.logins.getLoginsForProtectionSpace(
            login.protectionSpace,
            withUsername: login.username
        ).uponQueue(.main) { res in
            if let data = res.successValue {
                for saved in data {
                    if let saved = saved {
                        if saved.decryptedPassword == login.password {
                            _ = self.profile.logins.use(login: saved)
                            return
                        }

                        self.promptUpdateFromLogin(login: saved, toLogin: login)
                        return
                    }
                }
            }

            self.promptSave(login)
        }
    }

    private func promptSave(_ login: LoginEntry) {
        guard login.isValid.isSuccess else { return }

        let promptMessage: String
        let https = "^https:\\/\\/"
        let url = login.hostname.replacingOccurrences(of: https, with: "", options: .regularExpression, range: nil)
        let userName = login.username
        if !userName.isEmpty {
            promptMessage = String(format: .SaveLoginUsernamePrompt, userName, url)
        } else {
            promptMessage = String(format: .SaveLoginPrompt, url)
        }

        if let existingPrompt = self.snackBar {
            tab?.removeSnackbar(existingPrompt)
        }

        snackBar = TimerSnackBar(text: promptMessage, img: UIImage(named: StandardImageIdentifiers.Large.login))
        let dontSave = SnackButton(
            title: .LoginsHelperDontSaveButtonTitle,
            accessibilityIdentifier: "SaveLoginPrompt.dontSaveButton",
            bold: false
        ) { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            return
        }
        let save = SnackButton(
            title: .LoginsHelperSaveLoginButtonTitle,
            accessibilityIdentifier: "SaveLoginPrompt.saveLoginButton",
            bold: true
        ) { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            self.sendLoginsSavedTelemetry()
            _ = self.profile.logins.addLogin(login: login)
        }

        applyTheme(for: dontSave, save)
        snackBar?.addButton(dontSave)
        snackBar?.addButton(save)
        tab?.addSnackbar(snackBar!)
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

        if let existingPrompt = self.snackBar {
            tab?.removeSnackbar(existingPrompt)
        }

        snackBar = TimerSnackBar(text: formatted, img: UIImage(named: StandardImageIdentifiers.Large.login))
        let dontSave = SnackButton(
            title: .LoginsHelperDontUpdateButtonTitle,
            accessibilityIdentifier: "UpdateLoginPrompt.donttUpdateButton",
            bold: false
        ) { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
        }
        let update = SnackButton(
            title: .LoginsHelperUpdateButtonTitle,
            accessibilityIdentifier: "UpdateLoginPrompt.updateButton",
            bold: true
        ) { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            self.sendLoginsModifiedTelemetry()
            _ = self.profile.logins.updateLogin(id: old.id, login: new)
        }

        applyTheme(for: dontSave, update)
        snackBar?.addButton(dontSave)
        snackBar?.addButton(update)
        tab?.addSnackbar(snackBar!)
    }

    private func requestLogins(_ request: [String: Any], url: URL) {
        guard let requestId = request["requestId"] as? String,
            // Even though we don't currently use these two fields,
            // verify that they were received as additional confirmation
            // that this is a valid request from LoginsHelper.js.
            request["formOrigin"] as? String != nil,
            request["actionOrigin"] as? String != nil,

            // We pass in the webview's URL and derive the origin here
            // to workaround Bug 1194567.
            let origin = getOrigin(url.absoluteString)
        else { return }

        currentRequestId = requestId

        let protectionSpace = URLProtectionSpace.fromOrigin(origin)

        profile.logins.getLoginsForProtectionSpace(protectionSpace).uponQueue(.main) { res in
            guard let cursor = res.successValue else { return }

            let logins: [[String: Any]] = cursor.compactMap { login in
                // `requestLogins` is for webpage forms, not for HTTP Auth,
                // and the latter has httpRealm != nil; filter those out.
                return login?.httpRealm == nil ? login?.toJSONDict() : nil
            }

            let loginData = LoginInjectionData(requestId: self.currentRequestId,
                                               logins: logins)

            // NOTE: FXIOS-3856 This will get disabled in future with addtion of bottom sheet
            guard let tab = self.tab else {
                return
            }

            LoginsHelper.fillLoginDetails(with: tab, loginData: loginData)
        }
    }

    public static func fillLoginDetails(with tab: Tab,
                                        loginData: LoginInjectionData) {
        guard let injected = loginData.toJSONString() else { return }
        let injectJavaScript = "window.__firefox__.logins.inject(\(injected))"
        tab.webView?.evaluateJavascriptInDefaultContentWorld(injectJavaScript)
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .loginsAutofilled)
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
