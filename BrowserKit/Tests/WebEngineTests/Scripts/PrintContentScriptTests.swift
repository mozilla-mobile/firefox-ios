// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

@MainActor
@available(iOS 16.0, *)
final class PrintContentScriptTests: XCTestCase {
    private var webView: MockWKEngineWebView!

    override func setUp() {
        super.setUp()
        let webViewProvider = MockWKWebViewProvider()
        webView = webViewProvider.createWebview(
            configurationProvider: MockWKEngineConfigurationProvider(),
            parameters: WKWebViewParameters()
        ) as? MockWKEngineWebView
    }

    override func tearDown() {
        webView = nil
        super.tearDown()
    }

    func test_userContentController_withEmptyMessage_returnsDelegateCalled() {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: [])

        XCTAssertEqual(webView.viewPrintFormatterCalled, 1)
    }

    func test_userContentController_withMessage_returnsProperDelegateCall() {
        let subject = createSubject()

        subject.userContentController(didReceiveMessage: ["any message"])

        XCTAssertEqual(webView.viewPrintFormatterCalled, 1)
    }

    private func createSubject() -> PrintContentScript {
        let subject = PrintContentScript(webView: webView)
        trackForMemoryLeaks(subject)
        return subject
    }
}
