// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client

@MainActor
final class TranslationsEngineTests: XCTestCase {
    func test_bridgeTo_reusesBridgeForSameWebView() {
        let subject = createSubject()
        let pageWebView = WKWebView()

        let firstBridge = subject.bridge(to: pageWebView)
        let secondBridge = subject.bridge(to: pageWebView)

        XCTAssertTrue(
          firstBridge === secondBridge,
          "Expected bridge(to:) to reuse the same bridge instance for the same webview."
        )
    }

    func test_bridgeTo_createsDifferentBridgesForDifferentWebViews() {
        let subject = createSubject()
        let firstWebView = WKWebView()
        let secondWebView = WKWebView()

        let firstBridge = subject.bridge(to: firstWebView)
        let secondBridge = subject.bridge(to: secondWebView)

        XCTAssertFalse(
            firstBridge === secondBridge,
            "Expected bridge(to:) to create different bridge instances for different webviews."
        )
    }

    private func createSubject() -> TranslationsEngine {
        return TranslationsEngine(schemeHandler: MockSchemeHandler())
    }
}
