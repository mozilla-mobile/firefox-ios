// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Foundation

protocol WKUserScriptManager {
    func injectUserScriptsIntoWebView(_ webView: WKEngineWebView)
}

class DefaultUserScriptManager: WKUserScriptManager {
    // Scripts can use this to verify the application (not JS on the web) is calling into them.
    static let appIdToken = UUID().uuidString

    private var compiledUserScripts = [String: WKUserScript]()

    struct UserScriptInfo {
        let injectionTime: WKUserScriptInjectionTime
        let isMainFrame: Bool
    }

    init() {
        // Cache all of the pre-compiled user scripts so they don't
        // need re-fetched from disk for each webview.
        [UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentStart, isMainFrame: false),
         UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentEnd, isMainFrame: false),
         UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentStart, isMainFrame: true),
         UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentEnd, isMainFrame: true)].forEach { userScriptInfo in
            let fullName = buildScriptName(from: userScriptInfo)

            injectFrameScript(name: fullName, userScriptInfo: userScriptInfo)
            injectWebCompatScript(name: fullName, userScriptInfo: userScriptInfo)
        }
    }

    func injectUserScriptsIntoWebView(_ webView: WKEngineWebView) {
        // Start off by ensuring that any previously-added user scripts are
        // removed to prevent the same script from being injected twice.
        webView.configuration.userContentController.removeAllUserScripts()

        // Inject all pre-compiled user scripts.
        [UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentStart, isMainFrame: false),
         UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentEnd, isMainFrame: false),
         UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentStart, isMainFrame: true),
         UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentEnd, isMainFrame: true)].forEach { userScriptInfo in
            let fullName = buildScriptName(from: userScriptInfo)

            if let userScript = compiledUserScripts[fullName] {
                webView.configuration.userContentController.addUserScript(userScript)
            }

            let webcompatName = "Webcompat\(fullName)"
            if let webcompatUserScript = compiledUserScripts[webcompatName] {
                webView.configuration.userContentController.addUserScript(webcompatUserScript)
            }
        }
    }

    private func injectFrameScript(name: String, userScriptInfo: UserScriptInfo) {
        guard let path = Bundle.main.path(forResource: name, ofType: "js"),
              let source = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
        else { return }

        let wrappedSource = "(function() { const APP_ID_TOKEN = '\(DefaultUserScriptManager.appIdToken)'; \(source) })()"
        let userScript = WKUserScript.createInDefaultContentWorld(
            source: wrappedSource,
            injectionTime: userScriptInfo.injectionTime,
            forMainFrameOnly: userScriptInfo.isMainFrame
        )
        compiledUserScripts[name] = userScript
    }

    private func injectWebCompatScript(name: String, userScriptInfo: UserScriptInfo) {
        let webcompatName = "Webcompat\(name)"

        guard let webCompatPath = Bundle.main.path(forResource: webcompatName, ofType: "js"),
              let source = try? NSString(contentsOfFile: webCompatPath, 
                                         encoding: String.Encoding.utf8.rawValue) as String
        else { return }

        let wrappedSource = "(function() { const APP_ID_TOKEN = '\(DefaultUserScriptManager.appIdToken)'; \(source) })()"
        let userScript = WKUserScript.createInPageContentWorld(
            source: wrappedSource,
            injectionTime: userScriptInfo.injectionTime,
            forMainFrameOnly: userScriptInfo.isMainFrame
        )

        compiledUserScripts[webcompatName] = userScript
    }

    private func buildScriptName(from userScriptInfo: UserScriptInfo) -> String {
        let frameName = userScriptInfo.isMainFrame ? "MainFrame" : "AllFrames"
        let injectionTimeName = userScriptInfo.injectionTime == .atDocumentStart ? "Start" : "End"
        return frameName + "AtDocument" + injectionTimeName
    }
}
