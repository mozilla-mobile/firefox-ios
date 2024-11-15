// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

class UserScriptManager: FeatureFlaggable {
    // Scripts can use this to verify the *app* (not JS on the web) is calling into them.
    public static let appIdToken = UUID().uuidString

    // Singleton instance.
    public static let shared = UserScriptManager()

    private let compiledUserScripts: [String: WKUserScript]

    private let noImageModeUserScript = WKUserScript.createInDefaultContentWorld(
        source: "window.__firefox__.NoImageMode.setEnabled(true)",
        injectionTime: .atDocumentStart,
        forMainFrameOnly: true)
    private let nightModeUserScript = WKUserScript.createInDefaultContentWorld(
        source: "window.__firefox__.NightMode.setEnabled(true)",
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true)
    private let printHelperUserScript = WKUserScript.createInPageContentWorld(
        source: "window.print = function () { window.webkit.messageHandlers.printHandler.postMessage({}) }",
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false)

    private init() {
        var compiledUserScripts: [String: WKUserScript] = [:]

        // Cache all of the pre-compiled user scripts so they don't
        // need re-fetched from disk for each webview.
        [(WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: true),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: true)].forEach { arg in
            let (injectionTime, mainFrameOnly) = arg
            let mainframeString = mainFrameOnly ? "MainFrame" : "AllFrames"
            let injectionString = injectionTime == .atDocumentStart ? "Start" : "End"
            let name = mainframeString + "AtDocument" + injectionString
            if let path = Bundle.main.path(forResource: name, ofType: "js"),
                let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String {
                let wrappedSource = "(function() { const APP_ID_TOKEN = '\(UserScriptManager.appIdToken)'; \(source) })()"
                let userScript = WKUserScript.createInDefaultContentWorld(
                    source: wrappedSource,
                    injectionTime: injectionTime,
                    forMainFrameOnly: mainFrameOnly
                )
                compiledUserScripts[name] = userScript
            }

            // Autofill scripts
            let autofillName = "Autofill\(name)"
            if let autofillScriptCompatPath = Bundle.main.path(
                forResource: autofillName, ofType: "js"),
                let source = try? NSString(
                    contentsOfFile: autofillScriptCompatPath,
                    encoding: String.Encoding.utf8.rawValue) as String {
                let wrappedSource = "(function() { const APP_ID_TOKEN = '\(UserScriptManager.appIdToken)'; \(source) })()"
                let userScript = WKUserScript.createInDefaultContentWorld(
                    source: wrappedSource,
                    injectionTime: injectionTime,
                    forMainFrameOnly: mainFrameOnly)
                compiledUserScripts[autofillName] = userScript
            }

            let webcompatName = "Webcompat\(name)"
            if let webCompatPath = Bundle.main.path(
                forResource: webcompatName,
                ofType: "js"
            ),
               let source = try? NSString(
                contentsOfFile: webCompatPath,
                encoding: String.Encoding.utf8.rawValue
               ) as String {
                let wrappedSource = "(function() { const APP_ID_TOKEN = '\(UserScriptManager.appIdToken)'; \(source) })()"
                let userScript = WKUserScript.createInPageContentWorld(
                    source: wrappedSource,
                    injectionTime: injectionTime,
                    forMainFrameOnly: mainFrameOnly
                )
                compiledUserScripts[webcompatName] = userScript
            }
        }

        self.compiledUserScripts = compiledUserScripts
    }

    public func injectUserScriptsIntoWebView(_ webView: WKWebView?, nightMode: Bool, noImageMode: Bool) {
        // Start off by ensuring that any previously-added user scripts are
        // removed to prevent the same script from being injected twice.
        webView?.configuration.userContentController.removeAllUserScripts()

        // Inject all pre-compiled user scripts.
        [(WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: false),
         (WKUserScriptInjectionTime.atDocumentStart, mainFrameOnly: true),
         (WKUserScriptInjectionTime.atDocumentEnd, mainFrameOnly: true)].forEach { arg in
            let (injectionTime, mainFrameOnly) = arg
            let mainframeString = mainFrameOnly ? "MainFrame" : "AllFrames"
            let injectionString = injectionTime == .atDocumentStart ? "Start" : "End"
            let name = mainframeString + "AtDocument" + injectionString
            if let userScript = compiledUserScripts[name] {
                webView?.configuration.userContentController.addUserScript(userScript)
            }

            let autofillName = "Autofill\(name)"
            if let autofillScript = compiledUserScripts[autofillName] {
                webView?.configuration.userContentController.addUserScript(autofillScript)
            }

            let webcompatName = "Webcompat\(name)"
            if let webcompatUserScript = compiledUserScripts[webcompatName] {
                webView?.configuration.userContentController.addUserScript(webcompatUserScript)
            }
        }
        // Inject the Print Helper. This needs to be in the `page` content world in order to hook `window.print()`.
        webView?.configuration.userContentController.addUserScript(printHelperUserScript)
        // If Night Mode is enabled, inject a small user script to ensure
        // that it gets enabled immediately when the DOM loads.
        if nightMode {
            webView?.configuration.userContentController.addUserScript(nightModeUserScript)
        }
        // If No Image Mode is enabled, inject a small user script to ensure
        // that it gets enabled immediately when the DOM loads.
        if noImageMode {
            webView?.configuration.userContentController.addUserScript(noImageModeUserScript)
        }
    }
}
