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

    // MARK: Load URL

    func testLoadURLGivenEmptyThenDoesntLoad() {
        let subject = createSubject()
        let url = ""

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
    }

    func testLoadURLGivenNotAURLThenDoesntLoad() {
        let subject = createSubject()
        let url = "blablablablabla"

        subject?.load(url: url)

        // TODO: FXIOS-7981 Check scheme before loading
        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
    }

    func testLoadURLGivenNormalURLThenLoad() {
        let subject = createSubject()
        let url = "https://example.com"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
    }

    func testLoadURLGivenReaderModeURLThenLoad() {
        let subject = createSubject()
        let url = "about:reader?url=http://example.com"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
    }

    func testLoadURLGivenFileURLThenLoadFileURL() {
        let subject = createSubject()
        let url = "file:location"

        subject?.load(url: url)

        // TODO: FXIOS-7980 Review loadFileURL usage with isPrivileged
        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
    }

    // MARK: Stop URL

    func testStopLoading() {
        let subject = createSubject()

        subject?.stopLoading()

        XCTAssertEqual(webViewProvider.webView.stopLoadingCalled, 1)
    }

    // MARK: Go back

    func testGoBack() {
        let subject = createSubject()

        subject?.goBack()

        XCTAssertEqual(webViewProvider.webView.goBackCalled, 1)
    }

    // MARK: Go forward

    func testGoForward() {
        let subject = createSubject()

        subject?.goForward()

        XCTAssertEqual(webViewProvider.webView.goForwardCalled, 1)
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
