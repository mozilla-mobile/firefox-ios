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

class LoginsHelper: TabContentScript {
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
                options: .literal,
                range: nil,
                locale: nil)!
            string.replaceSubrange(range, with: replace)
            let nsRange = NSRange(location: string.distance(from: string.startIndex, to: range.lowerBound),
                                  length: replace.count)
            ranges.append(nsRange)
        }

        var attributes = [String: AnyObject]()
        attributes[NSAttributedStringKey.font] = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.regular)
        attributes[NSAttributedStringKey.foregroundColor] = UIColor.darkGray
        let attr = NSMutableAttributedString(string: string, attributes: attributes)
        let font: UIFont = UIFont.systemFont(ofSize: 13, weight: UIFont.Weight.medium)
        for range in ranges {
            attr.addAttribute(NSAttributedStringKey.font, value: font, range: range)
        }
        return attr
    }

    func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>> {
        return profile.logins.getLoginsForProtectionSpace(protectionSpace)
    }

    func updateLoginByGUID(_ guid: GUID, new: LoginData, significant: Bool) -> Success {
        return profile.logins.updateLoginByGUID(guid, new: new, significant: significant)
    }

    func setCredentials(_ login: LoginData) {
        if login.password.isEmpty {
            log.debug("Empty password")
            return
        }

        profile.logins
               .getLoginsForProtectionSpace(login.protectionSpace, withUsername: login.username)
               .uponQueue(.main) { res in
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

        let promptMessage: String
        if let username = login.username {
            promptMessage = String(format: Strings.SaveLoginUsernamePrompt, username, login.hostname)
        } else {
            promptMessage = String(format: Strings.SaveLoginPrompt, login.hostname)
        }

        if let existingPrompt = self.snackBar {
            tab?.removeSnackbar(existingPrompt)
        }

        snackBar = TimerSnackBar(text: promptMessage, img: UIImage(named: "key"))
        let dontSave = SnackButton(title: Strings.LoginsHelperDontSaveButtonTitle, accessibilityIdentifier: "SaveLoginPrompt.dontSaveButton") { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            return
        }
        let save = SnackButton(title: Strings.LoginsHelperSaveLoginButtonTitle, accessibilityIdentifier: "SaveLoginPrompt.saveLoginButton") { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            self.profile.logins.addLogin(login)
            LeanPlumClient.shared.track(event: .savedLoginAndPassword)
        }
        snackBar?.addButton(dontSave)
        snackBar?.addButton(save)
        tab?.addSnackbar(snackBar!)
    }

    fileprivate func promptUpdateFromLogin(login old: LoginData, toLogin new: LoginData) {
        guard new.isValid.isSuccess else {
            return
        }

        let guid = old.guid

        let formatted: String
        if let username = new.username {
            formatted = String(format: Strings.UpdateLoginUsernamePrompt, username, new.hostname)
        } else {
            formatted = String(format: Strings.UpdateLoginPrompt, new.hostname)
        }

        if let existingPrompt = self.snackBar {
            tab?.removeSnackbar(existingPrompt)
        }

        snackBar = TimerSnackBar(text: formatted, img: UIImage(named: "key"))
        let dontSave = SnackButton(title: Strings.LoginsHelperDontSaveButtonTitle, accessibilityIdentifier: "UpdateLoginPrompt.dontSaveButton") { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            return
        }
        let update = SnackButton(title: Strings.LoginsHelperUpdateButtonTitle, accessibilityIdentifier: "UpdateLoginPrompt.updateButton") { bar in
            self.tab?.removeSnackbar(bar)
            self.snackBar = nil
            self.profile.logins.updateLoginByGUID(guid, new: new, significant: new.isSignificantlyDifferentFrom(old))
        }
        snackBar?.addButton(dontSave)
        snackBar?.addButton(update)
        tab?.addSnackbar(snackBar!)
    }

    fileprivate func requestLogins(_ login: LoginData, requestId: String) {
        profile.logins.getLoginsForProtectionSpace(login.protectionSpace).uponQueue(.main) { res in
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
