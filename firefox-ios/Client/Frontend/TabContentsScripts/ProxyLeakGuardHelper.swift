// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

/// Receives reports from the proxy leak guard user script when it blocks an API that would
/// bypass the proxy. Message bodies are untrusted page input, so the origin always comes from
/// the sending frame, messages without the app ID token are dropped, and each API is reported at most
/// once per origin per tab.
@MainActor
final class ProxyLeakGuardHelper: TabContentScript {
    enum BlockedAPI: String {
        case webAuthnRelatedOrigin = "WebAuthnRelatedOrigin"
        case directConnection = "DirectConnection"

        var allowedKinds: Set<String> {
            switch self {
            case .webAuthnRelatedOrigin: return ["get", "create"]
            case .directConnection: return ["RTCPeerConnection", "webkitRTCPeerConnection", "WebTransport"]
            }
        }
    }

    nonisolated static let handlerName = "proxyLeakGuard"

    private var reported = Set<String>()

    /// Called with the blocked API and the origin of the frame that used it.
    var onBlockedRequest: (@MainActor (BlockedAPI, String) -> Void)?

    class func name() -> String {
        return "ProxyLeakGuardHelper"
    }

    func scriptMessageHandlerNames() -> [String]? {
        return [Self.handlerName]
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceiveScriptMessage message: WKScriptMessage
    ) {
        handle(body: message.body, origin: Self.originString(message.frameInfo.securityOrigin))
    }

    func handle(body: Any, origin: String) {
        guard let body = body as? [String: Any],
              body["token"] as? String == UserScriptManager.appIdToken,
              let api = (body["api"] as? String).flatMap(BlockedAPI.init(rawValue:)),
              let kind = body["kind"] as? String,
              api.allowedKinds.contains(kind),
              reported.insert("\(api.rawValue) \(origin)").inserted
        else { return }
        onBlockedRequest?(api, origin)
    }

    static func originString(_ origin: WKSecurityOrigin) -> String {
        let base = "\(origin.protocol)://\(origin.host)"
        return origin.port == 0 ? base : "\(base):\(origin.port)"
    }
}
