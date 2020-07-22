/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit

class UserScriptManager {

    // Scripts can use this to verify the *app* (not JS on the web) is calling into them.
    public static let appIdToken = UUID().uuidString

    // Singleton instance.
    public static let shared = UserScriptManager()

    private let compiledUserScripts: [String : WKUserScript]

    private let noImageModeUserScript = WKUserScript(source: "window.__firefox__.NoImageMode.setEnabled(true)", injectionTime: .atDocumentStart, forMainFrameOnly: true)
    private let nightModeUserScript = WKUserScript(source: "window.__firefox__.NightMode.setEnabled(true)", injectionTime: .atDocumentStart, forMainFrameOnly: true)

    private init() {
        var compiledUserScripts: [String : WKUserScript] = [:]

        // Cache all of the pre-compiled user scripts so they don't
        // need re-fetched from disk for each webview.
        [(WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: true),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: true)].forEach { arg in
            let (injectionTime, mainFrameOnly) = arg
            let name = (mainFrameOnly ? "MainFrame" : "AllFrames") + "AtDocument" + (injectionTime == .atDocumentStart ? "Start" : "End")
            if let path = Bundle.main.path(forResource: name, ofType: "js"),
                let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
                let wrappedSource = "(function() { const APP_ID_TOKEN = '\(UserScriptManager.appIdToken)'; \(source) })()"
                let userScript = WKUserScript(source: wrappedSource, injectionTime: injectionTime, forMainFrameOnly: mainFrameOnly)
                compiledUserScripts[name] = userScript
            }
        }

        self.compiledUserScripts = compiledUserScripts
    }

    public func injectUserScriptsIntoTab(_ tab: Tab, nightMode: Bool, noImageMode: Bool) {
        // Start off by ensuring that any previously-added user scripts are
        // removed to prevent the same script from being injected twice.
        tab.webView?.configuration.userContentController.removeAllUserScripts()

        // Inject all pre-compiled user scripts.
        [(WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: true),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: true)].forEach { arg in
            let (injectionTime, mainFrameOnly) = arg
            let name = (mainFrameOnly ? "MainFrame" : "AllFrames") + "AtDocument" + (injectionTime == .atDocumentStart ? "Start" : "End")
            if let userScript = compiledUserScripts[name] {
                tab.webView?.configuration.userContentController.addUserScript(userScript)
            }
        }
        // If Night Mode is enabled, inject a small user script to ensure
        // that it gets enabled immediately when the DOM loads.
        if nightMode {
            tab.webView?.configuration.userContentController.addUserScript(nightModeUserScript)
        }
        // If No Image Mode is enabled, inject a small user script to ensure
        // that it gets enabled immediately when the DOM loads.
        if noImageMode {
            tab.webView?.configuration.userContentController.addUserScript(noImageModeUserScript)
        }
    }
}
