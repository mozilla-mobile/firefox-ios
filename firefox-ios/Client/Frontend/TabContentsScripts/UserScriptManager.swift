// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import WebEngine

@MainActor
class UserScriptManager {
    // Scripts can use this to verify the *app* (not JS on the web) is calling into them.
    public static let appIdToken = UUID().uuidString

    // Singleton instance.
    public static let shared = UserScriptManager()

    private let compiledUserScripts: [String: WKUserScript]

    private let noImageModeUserScript = WKUserScript.createInDefaultContentWorld(
        source: "window.__firefox__.NoImageMode.setEnabled(true)",
        injectionTime: .atDocumentStart,
        forMainFrameOnly: true)
    private let nightModeUserScript = WKUserScript(
        source: NightModeHelper.jsCallbackBuilder(true),
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: true,
        in: .world(name: NightModeHelper.name()))
    private let backgroundAudioUserScript = WKUserScript.createInPageContentWorld(
        source: "window.__firefoxBackgroundAudioEnabled = true",
        injectionTime: .atDocumentStart,
        forMainFrameOnly: false)
    private let printHelperUserScript = WKUserScript.createInPageContentWorld(
        source: "window.print = function () { window.webkit.messageHandlers.printHandler.postMessage({}) }",
        injectionTime: .atDocumentEnd,
        forMainFrameOnly: false)

    /// Removes the JS entry points for two WebKit features that connect outside the proxy session,
    /// neither of which has a preference we can turn off:
    /// - WebAuthn: validating a cross-domain passkey makes WebKit fetch
    ///   `https://<rpId>/.well-known/webauthn`, handing the device's real IP to the relying party.
    ///   A ceremony only ever starts from `navigator.credentials`, so taking it away is enough.
    /// - WebTransport: its QUIC connections bypass the proxy entirely. WebKit only exposes it once
    ///   the OS has the full set of `nw_webtransport_*` symbols (iOS 26.4+, unconditional on iOS 27),
    ///   so this is inert on older systems and starts mattering after an OS update.
    ///
    /// Runs in the page content world to shadow the page's own globals, and in every frame since a
    /// subframe can reach both features too.
    private let proxyHardeningUserScript = WKUserScript.createInPageContentWorld(
        source: """
        (function() {
            const unsupported = () => Promise.reject(new DOMException('Not supported', 'NotAllowedError'));
            try {
                Object.defineProperty(window, 'PublicKeyCredential', { value: undefined, configurable: false });
                Object.defineProperty(navigator, 'credentials', {
                    value: Object.freeze({
                        get: unsupported,
                        create: unsupported,
                        store: unsupported,
                        preventSilentAccess: () => Promise.resolve()
                    }),
                    configurable: false
                });
                Object.defineProperty(window, 'WebTransport', { value: undefined, configurable: false });
            } catch (e) {}
        })();
        """,
        injectionTime: .atDocumentStart,
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
            UserScriptManager.addScripts(mainFrameOnly: mainFrameOnly,
                                         injectionTime: injectionTime,
                                         scripts: &compiledUserScripts)
        }

        self.compiledUserScripts = compiledUserScripts
    }

    private static func addScripts(mainFrameOnly: Bool,
                                   injectionTime: WKUserScriptInjectionTime,
                                   scripts: inout [String: WKUserScript]) {
        let mainframeString = mainFrameOnly ? "MainFrame" : "AllFrames"
        let injectionString = injectionTime == .atDocumentStart ? "Start" : "End"
        let name = mainframeString + "AtDocument" + injectionString
        if let source = UserScriptManager.getScriptSource(name) {
            let wrappedSource = "(function() { const APP_ID_TOKEN = '\(UserScriptManager.appIdToken)'; \(source) })()"
            let userScript = WKUserScript.createInDefaultContentWorld(
                source: wrappedSource,
                injectionTime: injectionTime,
                forMainFrameOnly: mainFrameOnly
            )
            scripts[name] = userScript
        }

        // NightMode scripts
        let nightModeName = "NightMode\(name)"
        if let source = UserScriptManager.getScriptSource(nightModeName) {
            let wrappedSource = "(function() { const APP_ID_TOKEN = '\(UserScriptManager.appIdToken)'; \(source) })()"
            let userScript = WKUserScript(
                source: wrappedSource,
                injectionTime: injectionTime,
                forMainFrameOnly: mainFrameOnly,
                in: .world(name: NightModeHelper.name()))
            scripts[nightModeName] = userScript
        }

        // Autofill scripts
        let autofillName = "Autofill\(name)"
        if let source = UserScriptManager.getScriptSource(autofillName) {
            let wrappedSource = "(function() { const APP_ID_TOKEN = '\(UserScriptManager.appIdToken)'; \(source) })()"
            let userScript = WKUserScript.createInDefaultContentWorld(
                source: wrappedSource,
                injectionTime: injectionTime,
                forMainFrameOnly: mainFrameOnly)
            scripts[autofillName] = userScript
        }

        let webcompatName = "Webcompat\(name)"
        if let source = UserScriptManager.getScriptSource(webcompatName) {
            let wrappedSource = "(function() { const APP_ID_TOKEN = '\(UserScriptManager.appIdToken)'; \(source) })()"
            let userScript = WKUserScript.createInPageContentWorld(
                source: wrappedSource,
                injectionTime: injectionTime,
                forMainFrameOnly: mainFrameOnly
            )
            scripts[webcompatName] = userScript
        }
    }

    private static func getScriptSource(_ scriptName: String) -> String? {
        guard let path = Bundle.main.path(forResource: scriptName, ofType: "js") else {
            return nil
        }
        return try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) as String
    }

    public func injectUserScriptsIntoWebView(_ webView: WKWebView?,
                                             nightMode: Bool,
                                             noImageMode: Bool,
                                             backgroundAudio: Bool) {
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

            let nightModeName = "NightMode\(name)"
            if let nightModeScript = compiledUserScripts[nightModeName] {
                webView?.configuration.userContentController.addUserScript(nightModeScript)
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
        if backgroundAudio {
            webView?.configuration.userContentController.addUserScript(backgroundAudioUserScript)
        }
        if DefaultWKEngineConfigurationProvider.isProxyEnabled {
            webView?.configuration.userContentController.addUserScript(proxyHardeningUserScript)
        }
    }
}
