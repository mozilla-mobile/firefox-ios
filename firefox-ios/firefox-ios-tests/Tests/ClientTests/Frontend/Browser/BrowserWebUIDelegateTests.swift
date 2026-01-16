// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebEngine
import WebKit
@testable import Client

// TODO: FXIOS-14534 - Add JavascriptPanel test in responder if WKFrameIngo limitation can be bypass
// The following WKUIDelegate methods cannot be unit tested due to WKFrameInfo:
// Technical reason: WKFrameInfo crashes during deallocation in tests, even when mocked.
// This is a WebKit limitation that cannot be worked around.
// - BrowserWebUIDelegate is a simple forwarding/routing layer with no business logic
// so unit test makes more sense to live in actual implementation like (engineResponder/legacyResponder)

@MainActor
final class BrowserWebUIDelegateTests: XCTestCase {
    private var mockLegacyResponder: MockLegacyResponder!
    private var engineResponder: MockWKUIHandler!

    private var webView: WKWebView {
        return MockTabWebView(
            tab: MockTab(
                profile: MockProfile(),
                windowUUID: .XCTestDefaultUUID
            )
        )
    }

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        let profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        engineResponder = MockWKUIHandler()
        mockLegacyResponder = MockLegacyResponder()
    }

    override func tearDown()  async throws {
        DependencyHelperMock().reset()
        engineResponder = nil
        mockLegacyResponder = nil
        try await super.tearDown()
    }

    func testCreateWebView_respondsToEngineResponder() {
        let subject = createSubject()

        _ = subject.webView(
            webView,
            createWebViewWith: WKWebViewConfiguration(),
            for: MockNavigationAction(url: URL(string: "https://www.google.com")!),
            windowFeatures: .init()
        )
        XCTAssertEqual(engineResponder.createWebViewCalled, 1)
        XCTAssertEqual(mockLegacyResponder.createWebViewCalled, 0)
    }

    func testWebViewDidClose_respondsToBrowserViewController() {
        let subject = createSubject()

        subject.webViewDidClose(webView)

        XCTAssertEqual(engineResponder.webViewDidCloseCalled, 0)
        XCTAssertEqual(mockLegacyResponder.webViewDidCloseCalled, 1)
    }

    private func createSubject() -> BrowserWebUIDelegate {
        let subject = BrowserWebUIDelegate(engineResponder: engineResponder, legacyResponder: mockLegacyResponder)
        trackForMemoryLeaks(subject)
        return subject
    }
}
