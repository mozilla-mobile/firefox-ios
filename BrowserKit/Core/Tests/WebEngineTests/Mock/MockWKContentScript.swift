// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockWKContentScript: WKContentScript {
    var userContentControllerCalled = 0
    var scriptMessageHandlerNamesCalled = 0
    var prepareForDeinitCalled = 0

    static func name() -> String {
        return "MockWKContentScript"
    }

    func scriptMessageHandlerNames() -> [String] {
        scriptMessageHandlerNamesCalled += 1
        return ["MockWKContentScriptHandler"]
    }

    func userContentController(didReceiveMessage message: Any) {
        userContentControllerCalled += 1
    }

    func prepareForDeinit() {
        prepareForDeinitCalled += 1
    }
}
