/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import WebKit
import Deferred
import SwiftyJSON

private let log = Logger.browserLogger

class LoginsHelper: TabHelper {
    fileprivate weak var tab: Tab?
    fileprivate let profile: Profile
    fileprivate var snackBar: SnackBar?

    // Exposed for mocking purposes
    var logins: BrowserLogins {
        return profile.logins
    }

    class func name() -> String {
        return "LoginsHelper"
    }

    required init(tab: Tab, profile: Profile) {
        self.tab = tab
        self.profile = profile

        if let path = Bundle.main.path(forResource: "LoginsHelper", ofType: "js"), let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
            let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "loginsManagerMessageHandler"
    }

    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard var res = message.body as? [String: AnyObject] else { return }
        guard let type = res["type"] as? String else { return }

        // Check to see that we're in the foreground before trying to check the logins. We want to
        // make sure we don't try accessing the logins database while we're backgrounded to avoid
        // the system from terminating our app due to background disk access.
        // 
        // See https://bugzilla.mozilla.org/show_bug.cgi?id=1307822 for details.
        guard UIApplication.shared.applicationState == .active && !profile.isShutdown else {
            return 
        }

        // We don't use the WKWebView's URL since the page can spoof the URL by using document.location
        // right before requesting login data. See bug 1194567 for more context.
        if let url = message.frameInfo.request.url {
            // Since responses go to the main frame, make sure we only listen for main frame requests
            // to avoid XSS attacks.
            if message.frameInfo.isMainFrame && type == "request" {
                res["username"] = "" as AnyObject?
                res["password"] = "" as AnyObject?
                if let login = Login.fromScript(url, script: res),
                   let requestId = res["requestId"] as? String {
                    requestLogins(login, requestId: requestId)
                }
            } else if type == "submit" {
                if self.profile.prefs.boolForKey("saveLogins") ?? true {
                    if let login = Login.fromScript(url, script: res) {
                        setCredentials(login)
                    }
                }
            }
        }
    }

    class func replace(_ base: String, keys: [String], replacements: [String]) -> NSMutableAttributedString {
        var ranges = [NSRange]()
        var string = base
        for (index, key) in keys.enumerated() {
            let replace = replacements[index]
            let range = string.range(of: key,
                options: NSString.CompareOptions.literal,
                range: nil,
                locale: nil)!
            string.replaceSubrange(range, with: replace)
            let nsRange = NSRange(location: string.characters.distance(from: string.startIndex, to: range.lowerBound),
                                  length: replace.characters.count)
            ranges.append(nsRange)
        }

        var attributes = [String: AnyObject]()
        attributes[NSFontAttributeName] = UIFont.systemFont(ofSize: 13, weight: UIFontWeightRegular)
        attributes[NSForegroundColorAttributeName] = UIColor.darkGray
        let attr = NSMutableAttributedString(string: string, attributes: attributes)
        let font: UIFont = UIFont.systemFont(ofSize: 13, weight: UIFontWeightMedium)
        for (_, range) in ranges.enumerated() {
            attr.addAttribute(NSFontAttributeName, value: font, range: range)
        }
        return attr
    }

    func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>> {
        return profile.logins.getLoginsForProtectionSpace(protectionSpace)
    }

    func updateLoginByGUID(_ guid: GUID, new: LoginData, significant: Bool) -> Success {
        return profile.logins.updateLoginByGUID(guid, new: new, significant: significant)
    }

    func removeLoginsWithGUIDs(_ guids: [GUID]) -> Success {
        return profile.logins.removeLoginsWithGUIDs(guids)
    }

    func setCredentials(_ login: LoginData) {
        if login.password.isEmpty {
            log.debug("Empty password")
            return
        }

        profile.logins
               .getLoginsForProtectionSpace(login.protectionSpace, withUsername: login.username)
               .uponQueue(DispatchQueue.main) { res in
            if let data = res.successValue {
                log.debug("Found \(data.count) logins.")
                for saved in data {
                    if let saved = saved {
                        if saved.password == login.password {
                            self.profile.logins.addUseOfLoginByGUID(saved.guid)
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

    fileprivate func promptSave(_ login: LoginData) {
        guard login.isValid.isSuccess else {
            return
        }

        let promptMessage: NSAttributedString
        if let username = login.username {
            let promptStringFormat = NSLocalizedString("LoginsHelper.PromptSaveLogin.Title", value: "Save login %@ for %@?", comment: "Prompt for saving a login. The first parameter is the username being saved. The second parameter is the hostname of the site.")
            promptMessage = NSAttributedString(string: String(format: promptStringFormat, username, login.hostname))
        } else {
            let promptStringFormat = NSLocalizedString("LoginsHelper.PromptSavePassword.Title", value: "Save password for %@?", comment: "Prompt for saving a password with no username. The parameter is the hostname of the site.")
            promptMessage = NSAttributedString(string: String(format: promptStringFormat, login.hostname))
        }

        if snackBar != nil {
            tab?.removeSnackbar(snackBar!)
        }

        snackBar = TimerSnackBar(attrText: promptMessage,
            img: UIImage(named: "key"),
            buttons: [
                SnackButton(title: Strings.LoginsHelperDontSaveButtonTitle, accessibilityIdentifier: "SaveLoginPrompt.dontSaveButton", callback: { (bar: SnackBar) -> Void in
                    self.tab?.removeSnackbar(bar)
                    self.snackBar = nil
                    return
                }),

                SnackButton(title: Strings.LoginsHelperSaveLoginButtonTitle, accessibilityIdentifier: "SaveLoginPrompt.saveLoginButton", callback: { (bar: SnackBar) -> Void in
                    self.tab?.removeSnackbar(bar)
                    self.snackBar = nil
                    self.profile.logins.addLogin(login)
                })
            ])
        tab?.addSnackbar(snackBar!)
    }

    fileprivate func promptUpdateFromLogin(login old: LoginData, toLogin new: LoginData) {
        guard new.isValid.isSuccess else {
            return
        }

        let guid = old.guid

        let formatted: String
        if let username = new.username {
            let promptStringFormat = NSLocalizedString("LoginsHelper.PromptUpdateLogin.Title", value: "Update login %@ for %@?", comment: "Prompt for updating a login. The first parameter is the username for which the password will be updated for. The second parameter is the hostname of the site.")
            formatted = String(format: promptStringFormat, username, new.hostname)
        } else {
            let promptStringFormat = NSLocalizedString("LoginsHelper.PromptUpdatePassword.Title", value: "Update password for %@?", comment: "Prompt for updating a password with no username. The parameter is the hostname of the site.")
            formatted = String(format: promptStringFormat, new.hostname)
        }
        let promptMessage = NSAttributedString(string: formatted)

        if snackBar != nil {
            tab?.removeSnackbar(snackBar!)
        }

        snackBar = TimerSnackBar(attrText: promptMessage,
            img: UIImage(named: "key"),
            buttons: [
                SnackButton(title: Strings.LoginsHelperDontSaveButtonTitle, accessibilityIdentifier: "UpdateLoginPrompt.dontSaveButton", callback: { (bar: SnackBar) -> Void in
                    self.tab?.removeSnackbar(bar)
                    self.snackBar = nil
                    return
                }),

                SnackButton(title: Strings.LoginsHelperUpdateButtonTitle, accessibilityIdentifier: "UpdateLoginPrompt.updateButton", callback: { (bar: SnackBar) -> Void in
                    self.tab?.removeSnackbar(bar)
                    self.snackBar = nil
                    self.profile.logins.updateLoginByGUID(guid, new: new,
                                                          significant: new.isSignificantlyDifferentFrom(old))
                })
            ])
        tab?.addSnackbar(snackBar!)
    }

    fileprivate func requestLogins(_ login: LoginData, requestId: String) {
        profile.logins.getLoginsForProtectionSpace(login.protectionSpace).uponQueue(DispatchQueue.main) { res in
            var jsonObj = [String: Any]()
            if let cursor = res.successValue {
                log.debug("Found \(cursor.count) logins.")
                jsonObj["requestId"] = requestId
                jsonObj["name"] = "RemoteLogins:loginsFound"
                jsonObj["logins"] = cursor.map { $0!.toDict() }
            }

            let json = JSON(jsonObj)
            let src = "window.__firefox__.logins.inject(\(json.stringValue()!))"
            self.tab?.webView?.evaluateJavaScript(src, completionHandler: { (obj, err) -> Void in
            })
        }
    }
}
