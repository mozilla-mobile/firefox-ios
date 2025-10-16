// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

/// TODO(Issam): Add comment explain why we need this in the first place.
/// It would have been easier if the aarchitecture could be modeled using a server like request-response.
/// But that's not possible with the way the code is setup now in JS.
/// Also the main reason we need a fancy bridge is that webkit postMessages don't support transferables.
/// So we can't forward a raw port between two webviews :(

/// Which side of the forwarder to send to.
enum BridgeSide { case left, right }

/// Super-small, generic protocol describing a forwarder.
@MainActor
protocol BridgeProtocol: AnyObject {
    func send(_ json: String, to side: BridgeSide)
}

/// Simple, bi-directional forwarder between two WKWebViews.
/// Forwards JSON messages left ⇄ right using a provided namespace.
@MainActor
final class WebViewBridge: NSObject, WKScriptMessageHandler, BridgeProtocol {
    private weak var leftView: WKWebView?
    private weak var rightView: WKWebView?

    // Both sides expose: window.<namespace>.receive(json)
    private var jsReceiveFn: String { "window.receive" }

    init(leftView: WKWebView, rightView: WKWebView) {
        self.leftView = leftView
        self.rightView = rightView
        super.init()
        // NOTE(Issam): We remove then add to make things idempotent
        // otherwise if for any reason we land here and we already have these setup, we will crash
        // TODO(Issam): Make these enums and probably namespace them translations-*,
        // we can have a custom data type for bridge ends maybe ?
        // TODO(Issam): We should probably make this a custom world at least for the page.
        leftView.configuration.userContentController.removeScriptMessageHandler(forName: "left")
        leftView.configuration.userContentController.add(self, contentWorld: .defaultClient, name: "left")
        // TODO(Issam): should only be done once since it's a one to many relationship
        rightView.configuration.userContentController.removeScriptMessageHandler(forName: "right")
        rightView.configuration.userContentController.add(self, contentWorld: .page, name: "right")
    }

    // TODO(Issam): Where is the best place to call this. Should we deinit as well ?
    func teardown() {
        leftView?.configuration.userContentController.removeScriptMessageHandler(forName: "left")
        rightView?.configuration.userContentController.removeScriptMessageHandler(forName: "right")
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(_ u: WKUserContentController, didReceive msg: WKScriptMessage) {
        guard JSONSerialization.isValidJSONObject(msg.body),
              let data = try? JSONSerialization.data(withJSONObject: msg.body),
              let json = String(data: data, encoding: .utf8) else { return }

        switch msg.name {
        case "left":
            send(json, to: .right)
        case "right":
            send(json, to: .left)
        default:
            break
        }
    }

    // MARK: - WebViewForwarderType
    // TODO(Issam): This is a bit wonky especially the bit with content worlds.r
    func send(_ json: String, to side: BridgeSide) {
        let targetView: WKWebView?
        let contentWorld: WKContentWorld
        switch side {
        case .left:
            targetView = leftView
            contentWorld = .defaultClient
        case .right:
            targetView = rightView
            contentWorld = .page
        }
        targetView?.evaluateJavaScript("\(jsReceiveFn)(\(json))", in: nil, in: contentWorld)
    }
}
