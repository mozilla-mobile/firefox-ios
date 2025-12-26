// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

@MainActor
@available(iOS 16.0, *)
final class WKUserScriptManagerTests: XCTestCase, @unchecked Sendable {
    func testInitThenAddsUserScripts() async {
        let subject = await createSubject()

        let userScripts = subject.compiledUserScripts
        XCTAssertEqual(userScripts.count, 8)
    }

    func testInjectUserScriptThenScriptsAreAddedInWebView() async {
        let webView = MockWKEngineWebView(frame: .zero,
                                          configurationProvider: MockWKEngineConfigurationProvider(),
                                          parameters: DefaultTestDependencies().webViewParameters)!
        let subject = await createSubject()

        subject.injectUserScriptsIntoWebView(webView)
        guard let config = webView.engineConfiguration as? MockWKEngineConfiguration else {
            XCTFail("Failed to cast webview engine configuration to MockWKEngineConfiguration")
            return
        }
        XCTAssertEqual(config.addUserScriptCalled, 9)
    }

    func createSubject() async -> DefaultUserScriptManager {
        let subject = DefaultUserScriptManager(scriptProvider: MockUserScriptProvider())
        trackForMemoryLeaks(subject)
        return subject
    }
}
