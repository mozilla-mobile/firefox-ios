// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockWKWebServerUtil: WKWebServerUtil {
    var setUpWebServerCalled = 0
    var stopWebServerCalled = 0

    func setUpWebServer(readerModeConfiguration: ReaderModeConfiguration) {
        setUpWebServerCalled += 1
    }

    func stopWebServer() {
        stopWebServerCalled += 1
    }
}
