// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

/// A concrete endpoint used by `WebViewBridge`.
/// This endpoint delivers messages into a `WKWebView` by calling a JavaScript function on the page.
final class WebViewBridgeEndpoint: BridgeEndpoint {
    /// The message handler name associated with this endpoint.
    ///
    /// JavaScript will post messages to:
    /// `window.webkit.messageHandlers[handlerName].postMessage(...)`
    public let handlerName: String

    /// The content world in which the JavaScript `receiveFunction` will run.
    ///
    /// This allows bridging between isolated JS contexts such as:
    /// - `.defaultClient` (isolated world)
    /// - `.page` (main world)
    private let contentWorld: WKContentWorld

    /// The global JavaScript function to invoke when sending messages
    /// into the page.
    ///
    /// Example: `"window.receive"`
    private let receiveFunction: String

    /// The underlying WebView. Weak to avoid retain cycles.
    private weak var webView: WKWebView?

    init(
        webView: WKWebView,
        handlerName: String,
        contentWorld: WKContentWorld,
        receiveFunction: String
    ) {
        self.webView = webView
        self.handlerName = handlerName
        self.contentWorld = contentWorld
        self.receiveFunction = receiveFunction
    }

    /// Sends the provided JSON string into the configured JavaScript function.
    func send(json: String) {
        guard let webView else { return }
        let js = "\(receiveFunction)(\(json))"
        webView.evaluateJavaScript(js, in: nil, in: contentWorld)
    }

    func registerScriptHandler(_ handler: WKScriptMessageHandler) {
        guard let webView else { return }
        let userContentController = webView.configuration.userContentController
        userContentController.removeScriptMessageHandler(forName: handlerName, contentWorld: contentWorld)
        userContentController.add(handler, contentWorld: contentWorld, name: handlerName)
    }

    func unregisterScriptHandler() {
        guard let webView else { return }
        let userContentController = webView.configuration.userContentController
        userContentController.removeScriptMessageHandler(forName: handlerName, contentWorld: contentWorld)
    }
}
