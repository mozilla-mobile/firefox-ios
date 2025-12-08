// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

@MainActor
final class TranslationsEngine {
    /// A single WKWebView managed by the engine.
    private let webView: WKWebView
    /// Keep bridges alive as long as their webviews exist.
    private let bridges = NSMapTable<WKWebView, Bridge>(
        keyOptions: [.weakMemory],
        valueOptions: [.strongMemory]
    )

    /// Used only for tests, to test if the bridges weak table releases objects after webviews are destroyed.
    var bridgeCount: Int {
        return bridges.objectEnumerator()?.allObjects.count ?? 0
    }

    /// Handler names and JS receive function used by the endpoints.
    /// These are used in `TranslationsEntrypoint.js` and `TranslationsEngine.js`
    /// These will be called from JS to deliver messages.
    /// e.g., `window.webkit.messageHandlers.left.postMessage(...)`
    private enum BridgeConfig {
        static let pageHandlerName   = "left"
        static let engineHandlerName = "right"
        static let receiveFunction   = "window.receive"
    }

    init(schemeHandler: WKURLSchemeHandler = TranslationsSchemeHandler()) {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(
            schemeHandler,
            forURLScheme: TranslationsSchemeHandler.scheme
        )

        self.webView = WKWebView(frame: .zero, configuration: config)
        self.webView.isHidden = true

        #if targetEnvironment(simulator)
        /// Allow Safari Web Inspector only when running in simulator.
        /// Requires to toggle `show features for web developers` in
        /// Safari > Settings > Advanced menu.
        if #available(iOS 16.4, *) {
            self.webView.isInspectable = true
        }
        /// NOTE:  The webview needs to be in the view tree to show up in the safari inspector.
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.addSubview(self.webView)
        }
        #endif

        loadEntrypointHTML()
    }

    /// Creates or reuses a bridge between the engine's webview and a page webview.
    func bridge(to pageWebView: WKWebView) -> Bridge {
        if let existing = bridges.object(forKey: pageWebView) {
            return existing
        }

        let pageEndpoint = WebViewBridgeEndpoint(
            webView: pageWebView,
            handlerName: BridgeConfig.pageHandlerName,
            contentWorld: .defaultClient,
            receiveFunction: BridgeConfig.receiveFunction
        )

        let engineEndpoint = WebViewBridgeEndpoint(
            webView: self.webView,
            handlerName: BridgeConfig.engineHandlerName,
            contentWorld: .page,
            receiveFunction: BridgeConfig.receiveFunction
        )

        let bridge = Bridge(portA: pageEndpoint, portB: engineEndpoint)
        bridges.setObject(bridge, forKey: pageWebView)
        return bridge
    }

    func removeBridge(for pageWebView: WKWebView) {
        bridges.object(forKey: pageWebView)?.teardown()
        bridges.removeObject(forKey: pageWebView)
    }

    /// Load the initial entrypoint for the engine.
    /// NOTE: This is loaded via the custom scheme defined in `TranslationsSchemeHandler` to avoid
    /// any security errors or CORS errors when loading other assets or workers.
    private func loadEntrypointHTML() {
        let appURL = URL(string: "translations://app/TranslationsEngine.html")!
        webView.load(URLRequest(url: appURL))
    }
}
