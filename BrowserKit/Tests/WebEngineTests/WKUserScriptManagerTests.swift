// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class WKUserScriptManagerTests: XCTestCase {
    func testInitThenAddsUserScripts() {
        let subject = createSubject()
        XCTAssertEqual(subject.compiledUserScripts.count, 8)
    }

    func testInjectUserScriptThenScriptsAreAddedInWebView() {
        let webview = MockWKEngineWebView(frame: .zero,
                                          configurationProvider: MockWKEngineConfigurationProvider())!
        let subject = createSubject()

        subject.injectUserScriptsIntoWebView(webview)

        // FXIOS-8115 Test that configuration has the scripts
    }

    func createSubject() -> DefaultUserScriptManager {
        let subject = DefaultUserScriptManager(scriptProvider: MockUserScriptProvider())
        // FXIOS-8115 Leaks caused by WKWebViewConfiguration
//        trackForMemoryLeaks(subject)
        return subject
    }
}
