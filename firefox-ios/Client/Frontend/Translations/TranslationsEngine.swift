// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

@MainActor
final class TranslationsEngine {

    /// TODO(Issam): Temporary for now to make sure we don't create more than one.
    /// For later, we either have to use a singelton or instantiate this somewhere with app lifetime.
    /// We could probably lazy load it but it's cheap enough that there is no need to do that maybe ?
    static let shared = TranslationsEngine()

    /// The custom HTML file this engine loads.
    private static let entrypointFile = "TranslationsEngine"

    /// The single WKWebView managed by the engine.
    private let webView: WKWebView

    // Keep bridges alive while their page webviews exist.
    private let bridges = NSMapTable<WKWebView, WebViewBridge>(
        keyOptions: [.weakMemory],
        valueOptions: [.strongMemory]
    )

    /// Private init so callers use `TranslationsEngine.shared`.
    private init() {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(TranslationsSchemeHandler(),
                                   forURLScheme: TranslationsSchemeHandler.scheme)
        // TODO(Issam): Maybe load the html from the same scheme too so we don't have to worry about CORS.
        // let appURL = URL(string: "translations://app/index.html")!
        // webView.load(URLRequest(url: appURL))
        // config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.isHidden = true

        #if targetEnvironment(simulator)
        // Allow Safari Web Inspector only when running in simulator.
        // Requires to toggle `show features for web developers` in
        // Safari > Settings > Advanced menu.
        if #available(iOS 16.4, *) {
            self.webView.isInspectable = true
        }
        // The webview needs to be in the view tree to show up in the inspector
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(self.webView)
        }
        #endif
        loadEntrypointHTML()
    }

    /// Create or reuse a bridge between the engine's webview and a page webview.
    @discardableResult
    func bridge(to pageWebView: WKWebView) -> WebViewBridge {
        // TODO(Issam): Is the reference to pageWebView strong ?
        if let existing = bridges.object(forKey: pageWebView) { return existing }
        let bridge = WebViewBridge(leftView: pageWebView, rightView: self.webView)
        bridges.setObject(bridge, forKey: pageWebView)
        return bridge
    }

    /// Optional: call when a page webview is going away.
    /// TODO(Issam): Make sure we call this when webview navigated away maybe or when destoryed ??
    func removeBridge(for pageWebView: WKWebView) {
        bridges.object(forKey: pageWebView)?.teardown()
        bridges.removeObject(forKey: pageWebView)
    }

    func translate(from: String, to: String) {
        // let translationsRS = ASTranslationModelsFetcher()
        // translationsRS?.fetchModels(from: pageLanguage, to: deviceLanguage)
        // TODO(Issam): Make sure from and to are safe to serialize
        let jsCall = """
        translate({ from: "\(from)", to: "\(to)" });
        """
        webView.evaluateJavaScript(jsCall) { result, error in
            if let error = error {
                // TODO(Issam): log something
                print("TranslationsEngine: translate error: \(error)")
            } else {
                // TODO(Issam): log something
                print("TranslationsEngine: translate result: \(String(describing: result))")
            }
        }
    }

    private func loadEntrypointHTML() {
        let appURL = URL(string: "translations://app/TranslationsEngine.html")!
        webView.load(URLRequest(url: appURL))
    }
}
