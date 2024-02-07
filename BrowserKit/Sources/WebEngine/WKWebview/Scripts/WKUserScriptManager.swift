// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import Foundation

/// Manager used to inject scripts at document start or end inside a WKEngineWebView
protocol WKUserScriptManager {
    func injectUserScriptsIntoWebView(_ webView: WKEngineWebView)
}

class DefaultUserScriptManager: WKUserScriptManager {
    // Scripts can use this to verify the application (not JS on the web) is calling into them
    private let appIdToken = UUID().uuidString
    private let scriptProvider: UserScriptProvider
    var compiledUserScripts = [String: WKUserScript]()

    private struct UserScriptInfo {
        let injectionTime: WKUserScriptInjectionTime
        let isMainFrame: Bool
    }

    init(scriptProvider: UserScriptProvider = DefaultUserScriptProvider()) {
        self.scriptProvider = scriptProvider
        injectUserScripts()
    }

    func injectUserScriptsIntoWebView(_ webView: WKEngineWebView) {
        // Remove any previously-added user scripts to prevent the same script from being injected twice
        webView.engineConfiguration.removeAllUserScripts()

        // Inject all pre-compiled user scripts.
        [
            UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentStart, isMainFrame: false),
            UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentEnd, isMainFrame: false),
            UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentStart, isMainFrame: true),
            UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentEnd, isMainFrame: true)
        ].forEach { userScriptInfo in
            let fullName = buildScriptName(from: userScriptInfo)

            if let userScript = compiledUserScripts[fullName] {
                webView.engineConfiguration.addUserScript(userScript)
            }

            let webcompatName = "Webcompat\(fullName)"
            if let webcompatUserScript = compiledUserScripts[webcompatName] {
                webView.engineConfiguration.addUserScript(webcompatUserScript)
            }
        }
    }

    /// Cache all of the pre-compiled user scripts so they don't need re-fetched from disk for each webview.
    private func injectUserScripts() {
        [
            UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentStart, isMainFrame: false),
            UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentEnd, isMainFrame: false),
            UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentStart, isMainFrame: true),
            UserScriptInfo(injectionTime: WKUserScriptInjectionTime.atDocumentEnd, isMainFrame: true)
        ].forEach { userScriptInfo in
            let fullName = buildScriptName(from: userScriptInfo)

            injectFrameScript(name: fullName, userScriptInfo: userScriptInfo)
            injectWebCompatScript(name: fullName, userScriptInfo: userScriptInfo)
        }
    }

    private func injectFrameScript(name: String, userScriptInfo: UserScriptInfo) {
        guard let source = scriptProvider.getScript(for: name) else { return }

        let wrappedSource = "(function() { const APP_ID_TOKEN = '\(appIdToken)'; \(source) })()"
        // Create in default content world
        let userScript = WKUserScript(source: wrappedSource,
                                      injectionTime: userScriptInfo.injectionTime,
                                      forMainFrameOnly: userScriptInfo.isMainFrame,
                                      in: .defaultClient)
        compiledUserScripts[name] = userScript
    }

    private func injectWebCompatScript(name: String, userScriptInfo: UserScriptInfo) {
        let webcompatName = "Webcompat\(name)"
        guard let source = scriptProvider.getScript(for: webcompatName) else { return }

        let wrappedSource = "(function() { const APP_ID_TOKEN = '\(appIdToken)'; \(source) })()"
        // Create in page content world
        let userScript = WKUserScript(source: wrappedSource,
                                      injectionTime: userScriptInfo.injectionTime,
                                      forMainFrameOnly: userScriptInfo.isMainFrame,
                                      in: .page)

        compiledUserScripts[webcompatName] = userScript
    }

    private func buildScriptName(from userScriptInfo: UserScriptInfo) -> String {
        let frameName = userScriptInfo.isMainFrame ? "MainFrame" : "AllFrames"
        let injectionTimeName = userScriptInfo.injectionTime == .atDocumentStart ? "Start" : "End"
        return frameName + "AtDocument" + injectionTimeName
    }
}
