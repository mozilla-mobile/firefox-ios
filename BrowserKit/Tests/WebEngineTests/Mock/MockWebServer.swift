// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockWebServer: WKEngineWebServerProtocol {
    var isRunning = false
    var startCalled = 0
    var stopCalled = 0
    var addTestHandlerCalled = 0
    var baseReaderModeURLCalled = 0
    var mockBaseReaderModeURL = ""

    func start() throws -> Bool {
        startCalled += 1
        return true
    }

    func stop() {
        stopCalled += 1
    }

    func addTestHandler() {
        addTestHandlerCalled += 1
    }

    func baseReaderModeURL() -> String {
        baseReaderModeURLCalled += 1
        return mockBaseReaderModeURL
    }
}
