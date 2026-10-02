// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client

@MainActor
final class BlankPageNavigationDelegateTests: XCTestCase {
    private var webView: WKWebView!
    private var subject: BlankPageNavigationDelegate?
    private var resumeCount = 0

    override func setUp() async throws {
        try await super.setUp()
        webView = WKWebView(frame: .zero)
        resumeCount = 0
    }

    override func tearDown() async throws {
        webView = nil
        subject = nil
        try await super.tearDown()
    }

    func testBeginAwaiting_withNilNavigation_resumesImmediately() async {
        let task = await startAwaiting(nil)

        await task.value

        XCTAssertEqual(resumeCount, 1)
    }

    func testDidFinish_forAwaitedNavigation_resumes() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)

        try XCTUnwrap(subject).webView(webView, didFinish: navigation)
        await task.value

        XCTAssertEqual(resumeCount, 1)
    }

    func testDidFail_forAwaitedNavigation_resumes() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)

        try XCTUnwrap(subject).webView(webView, didFail: navigation, withError: URLError(.cancelled))
        await task.value

        XCTAssertEqual(resumeCount, 1)
    }

    func testDidFailProvisionalNavigation_forAwaitedNavigation_resumes() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)

        try XCTUnwrap(subject).webView(
            webView,
            didFailProvisionalNavigation: navigation,
            withError: URLError(.cancelled)
        )
        await task.value

        XCTAssertEqual(resumeCount, 1)
    }

    func testWebContentProcessDidTerminate_resumes() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)

        try XCTUnwrap(subject).webViewWebContentProcessDidTerminate(webView)
        await task.value

        XCTAssertEqual(resumeCount, 1)
    }

    func testCallbacksForOtherNavigations_areIgnored() async throws {
        let navigation = try makeNavigation()
        let otherNavigation = try makeNavigation()
        let task = await startAwaiting(navigation)
        let subject = try XCTUnwrap(subject)

        subject.webView(webView, didFinish: otherNavigation)
        subject.webView(webView, didFail: otherNavigation, withError: URLError(.cancelled))
        subject.webView(webView, didFailProvisionalNavigation: nil, withError: URLError(.cancelled))
        await Task.yield()

        XCTAssertEqual(resumeCount, 0)

        subject.webView(webView, didFinish: navigation)
        await task.value

        XCTAssertEqual(resumeCount, 1)
    }

    func testRepeatedTerminalCallbacks_resumeOnlyOnce() async throws {
        let navigation = try makeNavigation()
        let task = await startAwaiting(navigation)
        let subject = try XCTUnwrap(subject)

        subject.webView(webView, didFinish: navigation)
        subject.webView(webView, didFail: navigation, withError: URLError(.cancelled))
        subject.webViewWebContentProcessDidTerminate(webView)
        await task.value

        XCTAssertEqual(resumeCount, 1)
    }

    // MARK: - Helpers

    /// `WKNavigation()` crashes on dealloc since its backing storage is only set up by WebKit,
    /// so navigations have to come from a real load.
    private func makeNavigation() throws -> WKNavigation {
        return try XCTUnwrap(webView.loadHTMLString("", baseURL: nil))
    }

    /// Creates the subject inside a continuation and returns the task awaiting it, once the
    /// subject is awaiting `navigation`.
    private func startAwaiting(_ navigation: WKNavigation?) async -> Task<Void, Never> {
        let task = Task {
            await withCheckedContinuation { continuation in
                let subject = BlankPageNavigationDelegate(continuation: continuation)
                self.subject = subject
                subject.beginAwaiting(navigation)
            }
            resumeCount += 1
        }
        while subject == nil {
            await Task.yield()
        }
        return task
    }
}
