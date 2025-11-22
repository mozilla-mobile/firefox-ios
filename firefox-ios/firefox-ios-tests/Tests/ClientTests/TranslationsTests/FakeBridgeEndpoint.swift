// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
@testable import Client

final class FakeEndpoint: BridgeEndpoint {
    let handlerName: String

    private(set) var receivedJSON: [String] = []
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0

    init(name: String) {
        self.handlerName = name
    }

    func send(json: String) {
        receivedJSON.append(json)
    }

    func registerScriptHandler(_ handler: WKScriptMessageHandler) {
        registerCount += 1
    }

    func unregisterScriptHandler() {
        unregisterCount += 1
    }
}
