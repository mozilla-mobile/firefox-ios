// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit

@MainActor
final class WKFrameInfoExtensionsTests: XCTestCase {
    let secureURL = URL(string: "https://foo.com")!
    let insecureURL = URL(string: "http://bar.com")!

    func test_insecureTopFrame_insecureFrame() {
        let webView = MockWKWebView(insecureURL)
        let frame = MockWKFrameInfo(webView: webView, frameURL: insecureURL)
        XCTAssertFalse(frame.isFrameLoadedInSecureContext)
    }

    func test_insecureTopFrame_secureFrame() {
        let webView = MockWKWebView(insecureURL)
        let frame = MockWKFrameInfo(webView: webView, frameURL: secureURL)
        XCTAssertFalse(frame.isFrameLoadedInSecureContext)
    }

    func test_secureTopFrame_insecureFrame() {
        let webView = MockWKWebView(secureURL)
        let frame = MockWKFrameInfo(webView: webView, frameURL: insecureURL)
        XCTAssertFalse(frame.isFrameLoadedInSecureContext)
    }

    func test_secureTopFrame_secureFrame() {
        let webView = MockWKWebView(secureURL)
        let frame = MockWKFrameInfo(webView: webView, frameURL: secureURL)
        XCTAssertTrue(frame.isFrameLoadedInSecureContext)
    }
}
