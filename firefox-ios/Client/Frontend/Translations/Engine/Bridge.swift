// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

/// A small bridge that forwards JSON messages between two `BridgeEndpoint` instances.
/// The two `BridgeEndpoint`instances  could be real webviews or fake for tests.
@MainActor
public final class Bridge: NSObject, WKScriptMessageHandler {
    private let portA: BridgeEndpoint
    private let portB: BridgeEndpoint

    init(portA: BridgeEndpoint, portB: BridgeEndpoint) {
        self.portA = portA
        self.portB = portB
        super.init()
        portA.registerScriptHandler(self)
        portB.registerScriptHandler(self)
    }

    func send(_ json: String, to endpoint: BridgeEndpoint) {
        endpoint.send(json: json)
    }

    func receive(handlerName: String, body: Any) {
        guard
            JSONSerialization.isValidJSONObject(body),
            let data = try? JSONSerialization.data(withJSONObject: body),
            let json = String(data: data, encoding: .utf8)
        else { return }

        if handlerName == portA.handlerName {
            portB.send(json: json)
        } else if handlerName == portB.handlerName {
            portA.send(json: json)
        }
    }

    func teardown() {
        portA.unregisterScriptHandler()
        portB.unregisterScriptHandler()
    }

    public func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        receive(handlerName: message.name, body: message.body)
    }
}
