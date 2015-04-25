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
private let CancelButtonTitle = NSLocalizedString("Cancel", comment: "Authentication prompt cancel button")
private let LoginButtonTitle  = NSLocalizedString("Login", comment: "Authentication prompt login button")

class PasswordHelper: BrowserHelper {
    private weak var browser: Browser?
    private let profile: Profile
    private var snackBar: SnackBar?
    private static let MaxAuthenticationAttempts = 3

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

    class func replace(base: String, keys: [String], replacements: [String]) -> NSMutableAttributedString {
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
                        // nop
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
        let formatted = String(format: promptStringFormat, password.username, password.hostname)
        let promptMessage = NSAttributedString(string: formatted)

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

    func handleAuthRequest(viewController: UIViewController, challenge: NSURLAuthenticationChallenge, completion: (password: Password?) -> Void) {
        // If there have already been too many login attempts, we'll just fail.
        if challenge.previousFailureCount >= PasswordHelper.MaxAuthenticationAttempts {
            completion(password: nil)
            return
        }

        var credential = challenge.proposedCredential

        // If we were passed an initial set of credentials from iOS, try and use them.
        if let proposed = credential {
            if !(proposed.user?.isEmpty ?? true) {
                if challenge.previousFailureCount == 0 {
                    completion(password: Password(credential: credential!, protectionSpace: challenge.protectionSpace))
                    return
                }
            } else {
                credential = nil
            }
        }

        if let credential = credential {
            // If we have some credentials, we'll show a prompt with them.
            let password = Password(credential: credential, protectionSpace: challenge.protectionSpace)
            promptForUsernamePassword(viewController, password: password, completion: completion)
        } else {
            // Otherwise, try to look one up
            let options = QueryOptions(filter: challenge.protectionSpace.host, filterType: .None, sort: .None)
            profile.passwords.get(options, complete: { (cursor) -> Void in
                var password = cursor[0] as? Password
                if password == nil {
                    password = Password(credential: nil, protectionSpace: challenge.protectionSpace)
                }
                self.promptForUsernamePassword(viewController, password: password!, completion: completion)
            })
        }
    }

    private func promptForUsernamePassword(viewController: UIViewController, password: Password, completion: (password: Password?) -> Void) {
        if password.hostname.isEmpty {
            println("Unable to show a password prompt without a hostname")
            completion(password: nil)
        }

        let alert: UIAlertController
        let title = NSLocalizedString("Authentication required", comment: "Authentication prompt title")
        if !password.httpRealm.isEmpty {
            let msg = NSLocalizedString("A username and password are being requested by %@. The site says: %@", comment: "Authentication prompt message with a realm. First parameter is the hostname. Second is the realm string")
            let formatted = NSString(format: msg, password.hostname, password.httpRealm) as String
            alert = UIAlertController(title: title, message: formatted, preferredStyle: UIAlertControllerStyle.Alert)
        } else {
            let msg = NSLocalizedString("A username and password are being requested by %@.", comment: "Authentication prompt message with no realm. Parameter is the hostname of the site")
            let formatted = NSString(format: msg, password.hostname) as String
            alert = UIAlertController(title: title, message: formatted, preferredStyle: UIAlertControllerStyle.Alert)
        }

        // Add a login button.
        let action = UIAlertAction(title: LoginButtonTitle,
            style: UIAlertActionStyle.Default) { (action) -> Void in
                let user = (alert.textFields?[0] as! UITextField).text
                let pass = (alert.textFields?[1] as! UITextField).text

                let credential = NSURLCredential(user: user, password: pass, persistence: .ForSession)
                let password = Password(credential: credential, protectionSpace: password.protectionSpace)
                completion(password: password)
                self.setPassword(password)
        }
        alert.addAction(action)

        // Add a cancel button.
        let cancel = UIAlertAction(title: CancelButtonTitle, style: UIAlertActionStyle.Cancel) { (action) -> Void in
            completion(password: nil)
            return
        }
        alert.addAction(cancel)

        // Add a username textfield.
        alert.addTextFieldWithConfigurationHandler { (textfield) -> Void in
            textfield.placeholder = NSLocalizedString("Username", comment: "Username textbox in Authentication prompt")
            textfield.text = password.username
        }

        // Add a password textfield.
        alert.addTextFieldWithConfigurationHandler { (textfield) -> Void in
            textfield.placeholder = NSLocalizedString("Password", comment: "Password textbox in Authentication prompt")
            textfield.secureTextEntry = true
            textfield.text = password.password
        }

        viewController.presentViewController(alert, animated: true) { () -> Void in }
    }

}