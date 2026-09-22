// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
@testable import Client

@MainActor
final class ReaderModeTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_pageShow_afterEnablingWebsiteDarkMode_reappliesDarkMode() throws {
        try assertPageShowReappliesNightMode(initiallyEnabled: false, enabled: true)
    }

    func test_pageShow_afterDisablingWebsiteDarkMode_reappliesLightMode() throws {
        try assertPageShowReappliesNightMode(initiallyEnabled: true, enabled: false)
    }

    private func assertPageShowReappliesNightMode(
        initiallyEnabled: Bool,
        enabled: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let tab = Tab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tab.nightMode = initiallyEnabled
        let webView = MockTabWebView(tab: tab)
        tab.webView = webView
        let readerMode = ReaderMode(tab: tab)
        let pageShow = ReaderPageShowMessage()
        readerMode.userContentController(webView.configuration.userContentController, didReceiveScriptMessage: pageShow)

        tab.nightMode = enabled
        webView.evaluatedScripts.removeAll()

        readerMode.userContentController(webView.configuration.userContentController, didReceiveScriptMessage: pageShow)

        XCTAssertEqual(webView.evaluatedScripts.count, 1, file: file, line: line)
        let evaluation = try XCTUnwrap(webView.evaluatedScripts.last, file: file, line: line)
        XCTAssertEqual(
            evaluation.script,
            "window.__firefox__.NightMode.setEnabled(\(enabled))",
            file: file,
            line: line
        )
        XCTAssertEqual(evaluation.world.name, "NightMode", file: file, line: line)
        XCTAssertEqual(webView.loadCalled, 0, file: file, line: line)
        XCTAssertEqual(webView.reloadFromOriginCalled, 0, file: file, line: line)
    }
}

private final class ReaderPageShowMessage: WKScriptMessage {
    override var body: Any {
        ["Type": "ReaderPageEvent", "Value": "PageShow"]
    }
}
