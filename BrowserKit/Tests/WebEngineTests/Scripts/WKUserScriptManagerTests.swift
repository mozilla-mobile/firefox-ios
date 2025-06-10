// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

@available(iOS 16.0, *)
final class WKUserScriptManagerTests: XCTestCase {
    func testInitThenAddsUserScripts() async {
        let subject = await createSubject()

        let userScripts = await subject.compiledUserScripts
        XCTAssertEqual(userScripts.count, 8)
    }

    func testInjectUserScriptThenScriptsAreAddedInWebView() async {
        let webview = await MockWKEngineWebView(frame: .zero,
                                                configurationProvider: MockWKEngineConfigurationProvider(),
                                                parameters: DefaultTestDependencies().webviewParameters)!
        let subject = await createSubject()

        await subject.injectUserScriptsIntoWebView(webview)
        guard let config = await webview.engineConfiguration as? MockWKEngineConfiguration else {
            XCTFail("Failed to cast webview engine configuration to MockWKEngineConfiguration")
            return
        }
        XCTAssertEqual(config.addUserScriptCalled, 9)
    }

    func createSubject() async -> DefaultUserScriptManager {
        let subject = await DefaultUserScriptManager(scriptProvider: MockUserScriptProvider())
        trackForMemoryLeaks(subject)
        return subject
    }
}
