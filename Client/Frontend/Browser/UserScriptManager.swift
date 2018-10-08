/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

class UserScriptManager {
    // Singleton.
    public static let `default` = UserScriptManager()

    // Scripts can use this to verify the app –not js on the page– is calling into them.
    public static let securityToken = UUID()

    private let userScripts: [WKUserScript]

    private init() {
        var userScripts: [WKUserScript] = []

        [(WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: true),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: true)].forEach { arg in
            let (injectionTime, mainFrameOnly) = arg
            let name = (mainFrameOnly ? "MainFrame" : "AllFrames") + "AtDocument" + (injectionTime == .atDocumentStart ? "Start" : "End")
            if let path = Bundle.main.path(forResource: name, ofType: "js"),
                let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
                let wrappedSource = "(function() { const SECURITY_TOKEN = \"\(UserScriptManager.securityToken)\"; \(source) })()"
                let userScript = WKUserScript(source: wrappedSource, injectionTime: injectionTime, forMainFrameOnly: mainFrameOnly)
                userScripts.append(userScript)
            }
        }

        self.userScripts = userScripts
    }

    public func injectUserScripts(tab: Tab) {
        userScripts.forEach { userScript in
            tab.webView?.configuration.userContentController.addUserScript(userScript)
        }

        // Inject user scripts for any installed WebExtensions.
        WebExtensionManager.default.webExtensions.forEach { webExtension in
            webExtension.userScripts.forEach { userScript in
                tab.webView?.configuration.userContentController.addUserScript(userScript)
            }
        }
    }
}
