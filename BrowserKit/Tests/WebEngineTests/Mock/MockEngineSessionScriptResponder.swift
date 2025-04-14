// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import WebEngine

class MockEngineSessionScriptResponder: EngineSessionScriptResponder {
    var contentScriptDidSendEventCalled = 0
    var lastContentScriptEvent: ScriptEvent?

    override func contentScriptDidSendEvent(_ event: ScriptEvent) {
        contentScriptDidSendEventCalled += 1
        lastContentScriptEvent = event
    }
}
