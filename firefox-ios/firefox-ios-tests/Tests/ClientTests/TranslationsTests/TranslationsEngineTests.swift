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

        XCTAssertTrue(firstBridge === secondBridge)
    }

    func test_bridgeTo_createsDifferentBridgesForDifferentWebViews() {
        let subject = createSubject()
        let firstWebView = WKWebView()
        let secondWebView = WKWebView()

        let firstBridge = subject.bridge(to: firstWebView)
        let secondBridge = subject.bridge(to: secondWebView)

        XCTAssertFalse(firstBridge === secondBridge)
    }

    func test_removeBridge_removesCachedBridge() {
        let subject = createSubject()
        let pageWebView = WKWebView()

        let firstBridge = subject.bridge(to: pageWebView)

        subject.removeBridge(for: pageWebView)

        let secondBridge = subject.bridge(to: pageWebView)

        XCTAssertFalse(firstBridge === secondBridge)
    }

    func test_removeBridge_isIdempotent() {
        let subject = createSubject()
        let pageWebView = WKWebView()

        XCTAssertNoThrow {
            subject.removeBridge(for: pageWebView)
            subject.removeBridge(for: pageWebView)
            subject.removeBridge(for: pageWebView)
        }
    }

    func test_NSMapTable_dropsEntryWhenWebViewIsDeallocated() {
        let engine = TranslationsEngine(schemeHandler: MockSchemeHandler())
        // We need a weak reference so we can check that WKWebView actually deallocates.
        weak var weakWebView: WKWebView?

        // Using an autoreleasepool just to mimic a context where something gets garbage collected
        autoreleasepool {
            let pageWebView = WKWebView()
            weakWebView = pageWebView
            // Adding the bridge stores the webview as a weak key in NSMapTable.
            _ = engine.bridge(to: pageWebView)
            XCTAssertEqual(engine.bridgeCount, 1)
        }

        // Force the main runloop to spin. WKWebView teardown seems to happens asynchronously on the main runloop.
        // Without this, the webview may stay alive for several cycles and NSMapTable won't clear its weak key yet.
        // RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.1))
        XCTAssertNil(weakWebView, "WKWebView should have been deallocated")
        XCTAssertEqual(engine.bridgeCount, 0)
    }

    private func createSubject() -> TranslationsEngine {
        return TranslationsEngine(schemeHandler: MockSchemeHandler())
    }
}
