// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import XCTest

/// Provides real `WKFrameInfo` and `WKSecurityOrigin` objects for tests.
/// These types can no longer be created or mocked safely, as WebKit now requires
/// fully initialized instances. This helper loads a lightweight `WKWebView`
/// navigation and captures the frame and origin values that WebKit supplies.
@MainActor
final class WebKitTestHelpers {
    final class FakeWKNavigationDelegate: NSObject, WKNavigationDelegate {
        let expect: XCTestExpectation
        var capturedFrame: WKFrameInfo?
        var capturedOrigin: WKSecurityOrigin?

        init(expect: XCTestExpectation) { self.expect = expect }

        private func webView(_ webView: WKWebView,
                             decidePolicyFor navigationAction: WKNavigationAction,
                             decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            let frame = navigationAction.sourceFrame
            capturedFrame = frame
            capturedOrigin = frame.securityOrigin
            decisionHandler(.allow)
            expect.fulfill()
            return
        }
    }

    // Loads a URL in a real WKWebView and returns the first valid
    // WKFrameInfo and WKSecurityOrigin from a navigation action.
    static func captureFrameAndOrigin(for url: URL, timeout: TimeInterval = 3.0) -> (WKFrameInfo, WKSecurityOrigin)? {
        let webView = WKWebView(frame: .zero)
        let expect = XCTestExpectation(description: "capture frame & origin")

        let delegate = FakeWKNavigationDelegate(expect: expect)
        webView.navigationDelegate = delegate

        // load a real https URL (use example.com to be safe)
        webView.load(URLRequest(url: url))

        let waiter = XCTWaiter.wait(for: [expect], timeout: timeout)
        if waiter == .completed, let frame = delegate.capturedFrame, let origin = delegate.capturedOrigin {
            return (frame, origin)
        }
        return nil
    }
}
