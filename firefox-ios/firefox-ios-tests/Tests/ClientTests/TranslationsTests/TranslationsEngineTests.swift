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

    func test_removeBridge_removesCachedBridge() {
        let subject = createSubject()
        let pageWebView = WKWebView()

        let firstBridge = subject.bridge(to: pageWebView)

        subject.removeBridge(for: pageWebView)

        let secondBridge = subject.bridge(to: pageWebView)

        XCTAssertFalse(
            firstBridge === secondBridge,
            "Expected removeBridge(for:) to clear the cached bridge so a subsequent bridge(to:) call returns a new instance."
        )
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
        waitForDeallocation(of: { weakWebView })
        XCTAssertNil(weakWebView, "WKWebView should have been deallocated")
        XCTAssertEqual(engine.bridgeCount, 0)
    }

    /// Spins the main runloop in small increments until the given object deallocates,
    /// or until the timeout expires. We need this because deallocation is not immediate.
    /// This will fail immediately if the object has not deallocated by the timeout.
    private func waitForDeallocation(of object: () -> AnyObject?, timeout: TimeInterval = 5) {
        let end = Date().addingTimeInterval(timeout)
        while Date() < end, object() != nil {
            RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        if object() != nil {
            XCTFail("Object not deallocated within \(timeout) seconds")
        }
    }

    private func createSubject() -> TranslationsEngine {
        return TranslationsEngine(schemeHandler: MockSchemeHandler())
    }
}
