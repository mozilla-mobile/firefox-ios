// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import XCTest

@testable import WebEngine

final class WKNavigationHandlerTests: XCTestCase {
    private var webView: MockWKWebView!
    private var sessionHandler: MockSessionHandler!
    override func setUp() {
        super.setUp()
        webView = MockWKWebView()
        sessionHandler = MockSessionHandler()
    }

    override func tearDown() {
        webView = nil
        sessionHandler = nil
        super.tearDown()
    }

    func testDidCommitCallsCommitURLChange() {
        let subject = createSubject()

        subject.webView(webView, didCommit: nil)

        XCTAssertEqual(sessionHandler.commitURLChangeCalled, 1)
    }

    func testDidFinishCallsFetchMetadata() {
        let subject = createSubject()
        webView.mockURL = URL(string: "www.example.com")!

        subject.webView(webView, didFinish: nil)

        XCTAssertEqual(sessionHandler.fetchMetadataCalled, 1)
    }

    func testDidFailProvisionalNavigationWhenWebkitError() {
        let subject = createSubject()

        let webKitError = NSError(domain: "WebKitErrorDomain", code: 102, userInfo: nil)
        subject.webView(webView, didFailProvisionalNavigation: nil, withError: webKitError)

        XCTAssertEqual(sessionHandler.commitURLChangeCalled, 0)
        XCTAssertEqual(sessionHandler.receivedErrorCalled, 0)
    }

    func testDidFailProvisionalNavigationWhenWebviewCrashed() {
        let subject = createSubject()
        let webContentProcessTerminatedError = NSError(
            domain: "WebKitErrorDomain",
            code: WKError.webContentProcessTerminated.rawValue,
            userInfo: nil
        )

        subject.webView(webView, didFailProvisionalNavigation: nil, withError: webContentProcessTerminatedError)

        XCTAssertEqual(webView.reloadCalled, 1)
    }

    func testDidFailProvisionalNavigationWhenCFURLErrorCancelled() {
        let subject = createSubject()
        let cfurlErrorCancelledError = NSError(
            domain: "SomeErrorDomain",
            code: Int(CFNetworkErrors.cfurlErrorCancelled.rawValue),
            userInfo: nil
        )

        subject.webView(webView, didFailProvisionalNavigation: nil, withError: cfurlErrorCancelledError)

        XCTAssertEqual(sessionHandler.commitURLChangeCalled, 1)
    }

    func testDidFailProvisionalNavigationWhenHasFailingURL() {
        let subject = createSubject()
        let failingURL = URL(string: "https://www.example.com")!
        let errorWithURL = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut, // Example error code
            userInfo: [NSURLErrorFailingURLErrorKey: failingURL]
        )

        subject.webView(webView, didFailProvisionalNavigation: nil, withError: errorWithURL)

        XCTAssertEqual(sessionHandler.receivedErrorCalled, 1)
    }

    // MARK: Helper

    func createSubject() -> DefaultNavigationHandler {
        let subject = DefaultNavigationHandler()
        subject.session = sessionHandler
        trackForMemoryLeaks(subject)
        return subject
    }
}
