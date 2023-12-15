// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class WKEngineSessionTests: XCTestCase {
    private var configurationProvider: MockWKEngineConfigurationProvider!
    private var webViewProvider: MockWKWebViewProvider!

    override func setUp() {
        super.setUp()
        configurationProvider = MockWKEngineConfigurationProvider()
        webViewProvider = MockWKWebViewProvider()
    }

    override func tearDown() {
        super.tearDown()
        configurationProvider = nil
        webViewProvider = nil
    }

    func testLoadURLGivenNotAURLThenDoesNothing() {
        let subject = createSubject()
        let url = "NotAURL"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
    }

    func testLoadURLGivenNormalURLThenLoadsRequest() {
        let subject = createSubject()
        let url = "https://example.com"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
    }

    func testLoadURLGivenReaderModeURLThenLoadsReques() {
        let subject = createSubject()
        let url = "file://location"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
    }

    // MARK: Helper

    func createSubject() -> WKEngineSession? {
        guard let subject = WKEngineSession(configurationProvider: configurationProvider,
                                            webViewProvider: webViewProvider) else {
            return nil
        }
        trackForMemoryLeaks(subject)
        return subject
    }
}
