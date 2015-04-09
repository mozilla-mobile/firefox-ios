/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import WebKit

private let SaveButtonTitle = NSLocalizedString("Save", comment: "Button to save the user's password")
private let NotNowButtonTitle = NSLocalizedString("Not now", comment: "Button to not save the user's password")
private let UpdateButtonTitle = NSLocalizedString("Update", comment: "Button to update the user's password")

class PasswordHelper: BrowserHelper {
    private weak var browser: Browser?
    private let profile: Profile
    private var snackBar: SnackBar?

    class func name() -> String {
        return "PasswordHelper"
    }

    required init(browser: Browser, profile: Profile) {
        self.browser = browser
        self.profile = profile

        if let path = NSBundle.mainBundle().pathForResource("PasswordHelper", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) as? String {
                var userScript = WKUserScript(source: source, injectionTime: WKUserScriptInjectionTime.AtDocumentEnd, forMainFrameOnly: true)
                browser.webView.configuration.userContentController.addUserScript(userScript)
            }
        }
    }

    func scriptMessageHandlerName() -> String? {
        return "passwordsManagerMessageHandler"
    }

    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        // println("DEBUG: passwordsManagerMessageHandler message: \(message.body)")
        var res = message.body as! [String: String]
        let type = res["type"]
        if let url = browser?.url {
            if type == "request" {
                res["username"] = ""
                res["password"] = ""
                let password = Password.fromScript(url, script: res)
                requestPasswords(password, requestId: res["requestId"]!)
            } else if type == "submit" {
                let password = Password.fromScript(url, script: res)
                setPassword(Password.fromScript(url, script: res))
            }
        }
    }

    private func replace(base: String, keys: [String], replacements: [String]) -> NSMutableAttributedString {
        var ranges = [NSRange]()
        var string = base
        for (index, key) in enumerate(keys) {
            let replace = replacements[index]
            let range = string.rangeOfString(key,
                options: NSStringCompareOptions.LiteralSearch,
                range: nil,
                locale: nil)!
            string.replaceRange(range, with: replace)
            let nsRange = NSMakeRange(distance(string.startIndex, range.startIndex),
                count(replace))
            ranges.append(nsRange)
        }

        var attributes = [NSObject: AnyObject]()
        attributes[NSFontAttributeName] = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Medium" : "HelveticaNeue", size: 13)
        attributes[NSForegroundColorAttributeName] = UIColor.darkGrayColor()
        var attr = NSMutableAttributedString(string: string, attributes: attributes)
        for (index, range) in enumerate(ranges) {
            attr.addAttribute(NSFontAttributeName, value: UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Bold" : "HelveticaNeue-Medium", size: 13)!, range: range)
        }
        return attr
    }

    private func setPassword(password: Password) {
        profile.passwords.get(QueryOptions(filter: password.hostname), complete: { data in
            for i in 0..<data.count {
                let savedPassword = data[i] as! Password
                if savedPassword.username == password.username {
                    if savedPassword.password == password.password {
                        return
                    }

                    self.promptUpdate(password)
                    return
                }
            }

           self.promptSave(password)
        })
    }

    private func promptSave(password: Password) {
        let promptStringFormat = NSLocalizedString("Do you want to save the password for %@ on %@?", comment: "Prompt for saving a password. The first parameter is the username being saved. The second parameter is the hostname of the site.")
        let promptMessage = NSAttributedString(string: String(format: promptStringFormat, password.username, password.hostname))

        if snackBar != nil {
            browser?.removeSnackbar(snackBar!)
        }

        snackBar = CountdownSnackBar(attrText: promptMessage,
            img: UIImage(named: "lock_verified"),
            buttons: [
                SnackButton(title: SaveButtonTitle, callback: { (bar: SnackBar) -> Void in
                    self.browser?.removeSnackbar(bar)
                    self.snackBar = nil
                    self.profile.passwords.add(password) { success in
                        // println("Add password \(success)")
                    }
                }),

                SnackButton(title: NotNowButtonTitle, callback: { (bar: SnackBar) -> Void in
                    self.browser?.removeSnackbar(bar)
                    self.snackBar = nil
                    return
                })
            ])
        browser?.addSnackbar(snackBar!)
    }

    private func promptUpdate(password: Password) {
        let promptStringFormat = NSLocalizedString("Do you want to update the password for %@ on %@?", comment: "Prompt for updating a password. The first parameter is the username being saved. The second parameter is the hostname of the site.")
        let promptMessage = NSAttributedString(string: String(format: promptStringFormat, password.username, password.hostname))

        if snackBar != nil {
            browser?.removeSnackbar(snackBar!)
        }

        snackBar = CountdownSnackBar(attrText: promptMessage,
            img: UIImage(named: "lock_verified"),
            buttons: [
                SnackButton(title: UpdateButtonTitle, callback: { (bar: SnackBar) -> Void in
                    self.browser?.removeSnackbar(bar)
                    self.snackBar = nil
                    self.profile.passwords.add(password) { success in
                        // println("Add password \(success)")
                    }
                }),
                SnackButton(title: NotNowButtonTitle, callback: { (bar: SnackBar) -> Void in
                    self.browser?.removeSnackbar(bar)
                    self.snackBar = nil
                    return
                })
            ])
        browser?.addSnackbar(snackBar!)
    }

    private func requestPasswords(password: Password, requestId: String) {
        profile.passwords.get(QueryOptions(filter: password.hostname), complete: { (cursor) -> Void in
            var logins = [[String: String]]()
            for i in 0..<cursor.count {
                let password = cursor[i] as! Password
                logins.append(password.toDict())
            }

            let jsonObj: [String: AnyObject] = [
                "requestId": requestId,
                "name": "RemoteLogins:loginsFound",
                "logins": logins
            ]

            let json = JSON(jsonObj)
            let src = "window.__firefox__.passwords.inject(\(json.toString()))"
            self.browser?.webView.evaluateJavaScript(src, completionHandler: { (obj, err) -> Void in
            })
        })
    }
}