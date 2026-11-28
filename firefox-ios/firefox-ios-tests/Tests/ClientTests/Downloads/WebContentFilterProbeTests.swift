// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client

@MainActor
final class WebContentFilterProbeTests: XCTestCase {
    private var webView: WKWebView!
    private var subject: WebContentFilterProbe?

    override func setUp() async throws {
        try await super.setUp()
        webView = WKWebView(frame: .zero)
    }

    override func tearDown() async throws {
        webView = nil
        subject = nil
        try await super.tearDown()
    }

    func testShouldCheck_onlyHTTPSchemes() {
        XCTAssertTrue(WebContentFilterProbe.shouldCheck(URL(string: "https://example.com")!))
        XCTAssertTrue(WebContentFilterProbe.shouldCheck(URL(string: "http://example.com/file")!))
        XCTAssertFalse(WebContentFilterProbe.shouldCheck(URL(string: "blob:https://example.com/id")!))
        XCTAssertFalse(WebContentFilterProbe.shouldCheck(URL(string: "file:///tmp/page.html")!))
        XCTAssertFalse(WebContentFilterProbe.shouldCheck(URL(string: "data:text/html,hi")!))
    }

    func testIsBlockedByContentFilter_matchesWebKitPolicyError() {
        let blocked = NSError(
            domain: WKErrorDomain,
            code: WebContentFilterProbe.blockedByContentFilterErrorCode,
            userInfo: [NSLocalizedDescriptionKey: "The URL was blocked by a content filter"]
        )
        XCTAssertTrue(WebContentFilterProbe.isBlockedByContentFilter(blocked))
        XCTAssertFalse(WebContentFilterProbe.isBlockedByContentFilter(
            NSError(domain: WKErrorDomain, code: 102)
        ))
        XCTAssertFalse(WebContentFilterProbe.isBlockedByContentFilter(URLError(.cancelled)))
    }

    func testIsSystemBlockPage_recognizesWebKitSubstituteDocument() {
        let blockPage = URL(string: "file:///System/Library/PrivateFrameworks/WebCore.framework/ContentFilterBlockedPage.html")
        let unblock = URL(string: "x-apple-content-filter://unblock")
        XCTAssertTrue(WebContentFilterProbe.isSystemBlockPage(blockPage))
        XCTAssertTrue(WebContentFilterProbe.isSystemBlockPage(unblock))
        XCTAssertFalse(WebContentFilterProbe.isSystemBlockPage(URL(string: "https://example.com")))
        XCTAssertFalse(WebContentFilterProbe.isSystemBlockPage(nil))
    }

    func testDidFail_resolvesBlocked() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)
        let error = NSError(domain: WKErrorDomain, code: WebContentFilterProbe.blockedByContentFilterErrorCode)

        try XCTUnwrap(subject).webView(webView, didFail: navigation, withError: error)

        let blocked = await task.value
        XCTAssertTrue(blocked)
    }

    func testProcessTermination_resolvesAllowed() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)

        try XCTUnwrap(subject).webViewWebContentProcessDidTerminate(webView)

        let blocked = await task.value
        XCTAssertFalse(blocked)
    }

    func testNilNavigation_resolvesAllowed() async {
        let task = await startAwaiting(nil)
        let blocked = await task.value
        XCTAssertFalse(blocked)
    }

    func testContentFilterFailure_resolvesBlocked() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)
        let error = NSError(domain: WKErrorDomain, code: WebContentFilterProbe.blockedByContentFilterErrorCode)

        try XCTUnwrap(subject).webView(webView, didFailProvisionalNavigation: navigation, withError: error)

        let blocked = await task.value
        XCTAssertTrue(blocked)
    }

    func testOtherFailure_resolvesAllowed() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)

        try XCTUnwrap(subject).webView(
            webView,
            didFailProvisionalNavigation: navigation,
            withError: URLError(.notConnectedToInternet)
        )

        let blocked = await task.value
        XCTAssertFalse(blocked)
    }

    func testDidCommit_resolvesAllowed() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)

        try XCTUnwrap(subject).webView(webView, didCommit: navigation)

        let blocked = await task.value
        XCTAssertFalse(blocked)
    }

    func testCallbacksForOtherNavigations_areIgnored() async throws {
        let navigation = try makeNavigation()
        let other = try makeNavigation()
        let task = await startAwaiting(navigation)
        let subject = try XCTUnwrap(subject)
        let error = NSError(domain: WKErrorDomain, code: WebContentFilterProbe.blockedByContentFilterErrorCode)

        subject.webView(webView, didFailProvisionalNavigation: other, withError: error)
        await Task.yield()
        subject.webView(webView, didCommit: navigation)

        let blocked = await task.value
        XCTAssertFalse(blocked)
    }

    func testRepeatedTerminalCallbacks_resumeOnlyOnce() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)
        let subject = try XCTUnwrap(subject)
        let error = NSError(domain: WKErrorDomain, code: WebContentFilterProbe.blockedByContentFilterErrorCode)

        subject.webView(webView, didFailProvisionalNavigation: navigation, withError: error)
        subject.webView(webView, didCommit: navigation)
        subject.webView(webView, didFinish: navigation)

        let blocked = await task.value
        XCTAssertTrue(blocked)
    }

    func testNonWebURL_isNotBlocked() async {
        let blocked = await WebContentFilterProbe().isBlocked(
            url: URL(string: "blob:https://example.com/id")!,
            dataStore: .default(),
            container: UIView()
        )
        XCTAssertFalse(blocked)
    }

    private func makeNavigation() throws -> WKNavigation {
        return try XCTUnwrap(webView.loadHTMLString("", baseURL: nil))
    }

    private func startAwaiting(_ navigation: WKNavigation?) async -> Task<Bool, Never> {
        let task = Task {
            await withCheckedContinuation { continuation in
                let subject = WebContentFilterProbe(continuation: continuation)
                self.subject = subject
                subject.beginAwaiting(navigation)
            }
        }
        while subject == nil {
            await Task.yield()
        }
        return task
    }
}
