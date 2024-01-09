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
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, url)
    }

    func testLoadURLGivenReaderModeURLThenLoad() {
        let subject = createSubject()
        let url = "about:reader?url=http://example.com"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString,
                       "http://localhost:0/reader-mode/page?url=http%3A%2F%2Fexample%2Ecom")
    }

    func testLoadURLGivenFileURLThenLoadFileURL() {
        let subject = createSubject()
        let url = "file://path/to/abc/dirA/A.html"

        subject?.load(url: url)

        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
        XCTAssertEqual(webViewProvider.webView.loadFileURLCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, "file://path/to/abc/dirA/A.html")
        XCTAssertEqual(webViewProvider.webView.loadFileReadAccessURL?.absoluteString, "file://path/to/abc/dirA/")
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

    // MARK: Reload

    func testReloadThenCallsReloadFromOrigin() {
        let subject = createSubject()

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 1)
    }

    func testReloadWhenErrorPageThenReplaceLocation() {
        let subject = createSubject()
        let errorPageURL = "errorpage"
        let internalURL = "internal://local/errorpage?url=\(errorPageURL)"
        subject?.load(url: internalURL)

        subject?.reload()

        XCTAssertEqual(webViewProvider.webView.reloadFromOriginCalled, 0)
        XCTAssertEqual(webViewProvider.webView.replaceLocationCalled, 1)
        XCTAssertEqual(webViewProvider.webView.url?.absoluteString, errorPageURL)
    }

    // MARK: Restore

    func testRestoreWhenNoLastRequestThenLoadNotCalled() {
        let subject = createSubject()
        let restoredState = Data()

        subject?.restoreState(state: restoredState)

        XCTAssertEqual(webViewProvider.webView.interactionState as! Data, restoredState)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 0)
    }

    func testRestoreWhenHasLastRequestThenLoadISCalled() {
        let subject = createSubject()
        let restoredState = Data()
        subject?.load(url: "https://example.com")

        subject?.restoreState(state: restoredState)

        XCTAssertEqual(webViewProvider.webView.interactionState as! Data, restoredState)
        XCTAssertEqual(webViewProvider.webView.loadCalled, 2, "Load calls it once, then restore calls it again")
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
