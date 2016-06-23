/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import WebKit
import Deferred

private let log = Logger.browserLogger

class LoginsHelper: TabHelper {
    private weak var tab: Tab?
    private let profile: Profile
    private var snackBar: SnackBar?

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

        if let path = NSBundle.mainBundle().pathForResource("LoginsHelper", ofType: "js"), source = try? NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String {
            let userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: false)
            tab.webView!.configuration.userContentController.addUserScript(userScript)
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "loginsManagerMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard var res = message.body as? [String: AnyObject] else { return }
        guard let type = res["type"] as? String else { return }

        // We don't use the WKWebView's URL since the page can spoof the URL by using document.location
        // right before requesting login data. See bug 1194567 for more context.
        if let url = message.frameInfo.request.URL {
            // Since responses go to the main frame, make sure we only listen for main frame requests
            // to avoid XSS attacks.
            if message.frameInfo.mainFrame && type == "request" {
                res["username"] = ""
                res["password"] = ""
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

    class func replace(base: String, keys: [String], replacements: [String]) -> NSMutableAttributedString {
        var ranges = [NSRange]()
        var string = base
        for (index, key) in keys.enumerate() {
            let replace = replacements[index]
            let range = string.rangeOfString(key,
                options: NSStringCompareOptions.LiteralSearch,
                range: nil,
                locale: nil)!
            string.replaceRange(range, with: replace)
            let nsRange = NSMakeRange(string.startIndex.distanceTo(range.startIndex),
                replace.characters.count)
            ranges.append(nsRange)
        }

        var attributes = [String: AnyObject]()
        attributes[NSFontAttributeName] = UIFont.systemFontOfSize(13, weight: UIFontWeightRegular)
        attributes[NSForegroundColorAttributeName] = UIColor.darkGrayColor()
        let attr = NSMutableAttributedString(string: string, attributes: attributes)
        let font: UIFont = UIFont.systemFontOfSize(13, weight: UIFontWeightMedium)
        for (_, range) in ranges.enumerate() {
            attr.addAttribute(NSFontAttributeName, value: font, range: range)
        }
        return attr
    }

    func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>> {
        return profile.logins.getLoginsForProtectionSpace(protectionSpace)
    }

    func updateLoginByGUID(guid: GUID, new: LoginData, significant: Bool) -> Success {
        return profile.logins.updateLoginByGUID(guid, new: new, significant: significant)
    }

    func removeLoginsWithGUIDs(guids: [GUID]) -> Success {
        return profile.logins.removeLoginsWithGUIDs(guids)
    }

    func setCredentials(login: LoginData) {
        if login.password.isEmpty {
            log.debug("Empty password")
            return
        }

        profile.logins
               .getLoginsForProtectionSpace(login.protectionSpace, withUsername: login.username)
               .uponQueue(dispatch_get_main_queue()) { res in
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

    private func promptSave(login: LoginData) {
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

    private func promptUpdateFromLogin(login old: LoginData, toLogin new: LoginData) {
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

    private func requestLogins(login: LoginData, requestId: String) {
        profile.logins.getLoginsForProtectionSpace(login.protectionSpace).uponQueue(dispatch_get_main_queue()) { res in
            var jsonObj = [String: AnyObject]()
            if let cursor = res.successValue {
                log.debug("Found \(cursor.count) logins.")
                jsonObj["requestId"] = requestId
                jsonObj["name"] = "RemoteLogins:loginsFound"
                jsonObj["logins"] = cursor.map { $0!.toDict() }
            }

            let json = JSON(jsonObj)
            let src = "window.__firefox__.logins.inject(\(json.toString()))"
            self.tab?.webView?.evaluateJavaScript(src, completionHandler: { (obj, err) -> Void in
            })
        }
    }
}
