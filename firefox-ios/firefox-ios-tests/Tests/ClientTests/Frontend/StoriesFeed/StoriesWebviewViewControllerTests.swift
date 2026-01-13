// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import XCTest

@testable import Client

final class StoriesWebviewViewControllerTests: XCTestCase {
    @MainActor
    func test_decidePolicy_alwaysAllow() throws {
        let subject = createSubject()

        let expectation = expectation(description: "decision")
        subject.webView(WKWebView(), decidePolicyFor: WKNavigationAction()) { policy in
            XCTAssertEqual(policy, .allow)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.1)
    }

    @MainActor
    func test_createWebViewWith_alwaysAllow() throws {
        let subject = createSubject()

        let expectation = expectation(description: "WebView finished loading")

        let navigationAction = MockNavigationAction(url: URL(string: "http://mozilla.com")!)
        let webView = MockWKWebView(URL(string: "http://wikipedia.org")!)
        webView.didLoad = { expectation.fulfill() }

        let newWebView = subject.webView(webView,
                                         createWebViewWith: WKWebViewConfiguration(),
                                         for: navigationAction,
                                         windowFeatures: WKWindowFeatures())

        // Nil because we are not creating a new webview
        XCTAssertNil(newWebView)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(webView.url.absoluteString, "http://mozilla.com")
    }

    @MainActor
    private func createSubject() -> StoriesWebviewViewController {
        let notificationCenter = MockNotificationCenter()
        let themeManager = MockThemeManager()
        let storiesWebviewViewController = StoriesWebviewViewController(profile: MockProfile(),
                                                                        windowUUID: .XCTestDefaultUUID,
                                                                        themeManager: themeManager,
                                                                        notificationCenter: notificationCenter)
        trackForMemoryLeaks(storiesWebviewViewController)
        return storiesWebviewViewController
    }
}
