// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import XCTest
import Common
import Shared

@testable import Client

/// Tests for KVO observer management in BrowserViewController.
/// Verifies that the fix for the collection mutation bug correctly removes all observers.
@MainActor
final class BrowserViewControllerKVOTests: XCTestCase, StoreTestUtility {
    var profile: MockProfile!
    var tabManager: MockTabManager!
    var mockStore: MockStoreForMiddleware<AppState>!
    var appState: AppState!

    override func setUp() async throws {
        try await super.setUp()
        tabManager = MockTabManager()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManager)
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        setupStore()
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        tabManager = nil
        resetStore()
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - beginObserving Tests

    func testBeginObserving_addsWebViewToObservedList() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.createWebview(configuration: .init())

        guard let webView = tab.webView else {
            XCTFail("WebView should not be nil")
            return
        }

        subject.beginObserving(webView: webView)

        XCTAssertTrue(subject.observedWebViews.contains(webView))
    }

    func testBeginObserving_doesNotAddDuplicateWebView() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.createWebview(configuration: .init())

        guard let webView = tab.webView else {
            XCTFail("WebView should not be nil")
            return
        }

        subject.beginObserving(webView: webView)
        subject.beginObserving(webView: webView)

        XCTAssertEqual(subject.observedWebViews.count, 1, "WebView should only be added once")
    }

    // MARK: - stopObserving Tests

    func testStopObserving_removesWebViewFromObservedList() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.createWebview(configuration: .init())

        guard let webView = tab.webView else {
            XCTFail("WebView should not be nil")
            return
        }

        subject.beginObserving(webView: webView)
        XCTAssertTrue(subject.observedWebViews.contains(webView))

        subject.stopObserving(webView: webView)
        XCTAssertFalse(subject.observedWebViews.contains(webView))
    }

    func testStopObserving_doesNotCrashOnUnobservedWebView() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.createWebview(configuration: .init())

        guard let webView = tab.webView else {
            XCTFail("WebView should not be nil")
            return
        }

        // This should not crash or throw - just log a warning
        subject.stopObserving(webView: webView)

        XCTAssertFalse(subject.observedWebViews.contains(webView))
    }

    // MARK: - stopObservingAllWebViews Tests

    /// This test verifies that the fix for the collection mutation bug
    /// correctly removes ALL observers, not just some of them.
    func testStopObservingAllWebViews_removesAllObservers() {
        let subject = createSubject()

        // Create multiple tabs with webViews
        let tab1 = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let tab2 = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let tab3 = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)

        tab1.createWebview(configuration: .init())
        tab2.createWebview(configuration: .init())
        tab3.createWebview(configuration: .init())

        guard let webView1 = tab1.webView,
              let webView2 = tab2.webView,
              let webView3 = tab3.webView else {
            XCTFail("WebViews should not be nil")
            return
        }

        // Begin observing all webViews
        subject.beginObserving(webView: webView1)
        subject.beginObserving(webView: webView2)
        subject.beginObserving(webView: webView3)

        // Verify all are being observed
        var initialCount = 0
        for _ in subject.observedWebViews {
            initialCount += 1
        }
        XCTAssertEqual(initialCount, 3, "Should have 3 observed webViews")

        // Remove all observers - this is the fix being tested
        subject.stopObservingAllWebViews()

        // Verify ALL observers were removed (not just some)
        var finalCount = 0
        for _ in subject.observedWebViews {
            finalCount += 1
        }
        XCTAssertEqual(finalCount, 0, "All observers should be removed")
        XCTAssertFalse(subject.observedWebViews.contains(webView1))
        XCTAssertFalse(subject.observedWebViews.contains(webView2))
        XCTAssertFalse(subject.observedWebViews.contains(webView3))
    }

    func testStopObservingAllWebViews_handlesEmptyList() {
        let subject = createSubject()

        // Verify list starts empty
        var initialCount = 0
        for _ in subject.observedWebViews {
            initialCount += 1
        }
        XCTAssertEqual(initialCount, 0)

        // This should not crash
        subject.stopObservingAllWebViews()

        // Verify still empty
        var finalCount = 0
        for _ in subject.observedWebViews {
            finalCount += 1
        }
        XCTAssertEqual(finalCount, 0)
    }

    func testStopObservingAllWebViews_handlesSingleObserver() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.createWebview(configuration: .init())

        guard let webView = tab.webView else {
            XCTFail("WebView should not be nil")
            return
        }

        subject.beginObserving(webView: webView)

        var initialCount = 0
        for _ in subject.observedWebViews {
            initialCount += 1
        }
        XCTAssertEqual(initialCount, 1)

        subject.stopObservingAllWebViews()

        var finalCount = 0
        for _ in subject.observedWebViews {
            finalCount += 1
        }
        XCTAssertEqual(finalCount, 0)
    }

    // MARK: - Notification & Crash Safety Tests

    func testWillTerminateNotification_removesAllObservers() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.createWebview(configuration: .init())
        guard let webView = tab.webView else { XCTFail("WebView should not be nil"); return }

        subject.beginObserving(webView: webView)
        XCTAssertTrue(subject.observedWebViews.contains(webView))

        // Simulate the willTerminate notification by calling handleNotifications directly.
        // The BVC only subscribes to notifications during viewDidLoad, so we invoke the
        // handler without loading the full view hierarchy.
        let notification = Notification(name: UIApplication.willTerminateNotification)
        subject.handleNotifications(notification)

        XCTAssertFalse(subject.observedWebViews.contains(webView))
    }

    func testStopObservingAllWebViews_calledTwice_doesNotCrash() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.createWebview(configuration: .init())
        guard let webView = tab.webView else { XCTFail("WebView should not be nil"); return }

        subject.beginObserving(webView: webView)
        subject.stopObservingAllWebViews()
        subject.stopObservingAllWebViews()

        var count = 0
        for _ in subject.observedWebViews { count += 1 }
        XCTAssertEqual(count, 0)
    }

    func testStopObservingAllWebViews_withDeallocatedWebViews_doesNotCrash() {
        let subject = createSubject()

        autoreleasepool {
            let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
            tab.createWebview(configuration: .init())
            if let webView = tab.webView {
                subject.beginObserving(webView: webView)
            }
        }

        subject.stopObservingAllWebViews()

        var count = 0
        for _ in subject.observedWebViews { count += 1 }
        XCTAssertEqual(count, 0)
    }

    // MARK: - Private

    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> BrowserViewController {
        let subject = BrowserViewController(profile: profile,
                                            tabManager: tabManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> Client.AppState {
        let appState = AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    )
                ]
            )
        )
        self.appState = appState
        return appState
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
