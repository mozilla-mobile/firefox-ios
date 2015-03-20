/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 g* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import WebKit

class PasswordManager: BrowserHelper {
    private weak var browser: Browser?
    private let profile: Profile

    class func name() -> String {
        return "PasswordManager"
    }

    required init(browser: Browser, profile: Profile) {
        self.browser = browser
        self.profile = profile

        if let path = NSBundle.mainBundle().pathForResource("Passwords", ofType: "js") {
            if let source = NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil) {
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
        var res = message.body as [String: String]
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

    private func setPassword(pswd: Password) {
        // TODO: Prompt before adding passwords
        // profile.passwords.add(pswd) { success in
            // println("Add password \(success)")
        // }
    }

    private func requestPasswords(password: Password, requestId: String) {
        profile.passwords.get(QueryOptions(filter: password.hostname), complete: { (cursor) -> Void in
            var logins = [[String: String]]()
            for i in 0..<cursor.count {
                let password = cursor[i] as Password
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