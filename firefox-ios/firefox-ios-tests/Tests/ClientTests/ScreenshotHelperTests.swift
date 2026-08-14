// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class ScreenshotHelperTests: XCTestCase, StoreTestUtility {
    var profile: MockProfile!
    let tabManager = MockTabManager()
    var mockVC: MockBrowserViewController!
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
        mockVC = MockBrowserViewController(profile: profile, tabManager: tabManager)
        setupStore()
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        DependencyHelperMock().reset()
        mockVC = nil
        resetStore()
        try await super.tearDown()
    }

    func testTakeScreenshotForHomepage() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let homeURL = URL(string: "internal://local/about/home")
        let mockTabWebView = MockTabWebView(tab: tab)
        tabManager.selectedTab = tab

        mockTabWebView.loadedURL = homeURL
        tab.webView = mockTabWebView
        tab.url = homeURL

        subject.takeScreenshot(tab, windowUUID: .XCTestDefaultUUID, screenshotBounds: .zero)

        guard let screenshotAction = mockStore.dispatchedActions.first as? ScreenshotAction else {
            XCTFail("fired action was not of the expected type")
            return
        }

        XCTAssertEqual(tab.screenshot, UIImage.checkmark)
        XCTAssertTrue(tab.hasHomeScreenshot)
        XCTAssertEqual(screenshotAction.tab, tab)
        XCTAssertNil(screenshotAction.screenshotToPersist,
                     "Homepage screenshots are already backed by memory this process owns, so no copy is needed.")
    }

    func testTakeScreenshotFromErrorPage() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let homeURL = URL(string: "https://example.com")
        let mockTabWebView = MockTabWebView(tab: tab)

        mockVC.mockContentContainer.shouldHaveNativeErrorPage = true
        mockTabWebView.loadedURL = homeURL
        tab.webView = mockTabWebView
        tab.url = homeURL

        subject.takeScreenshot(tab, windowUUID: .XCTestDefaultUUID, screenshotBounds: .zero)

        guard let screenshotAction = mockStore.dispatchedActions.first as? ScreenshotAction else {
            XCTFail("fired action was not of the expected type")
            return
        }

        XCTAssertEqual(screenshotAction.tab, tab)
        XCTAssertEqual(tab.screenshot, UIImage.checkmark)
        XCTAssertFalse(tab.hasHomeScreenshot)
        XCTAssertNil(screenshotAction.screenshotToPersist,
                     "Error page screenshots are already backed by memory this process owns, so no copy is needed.")
    }

    func testTakeScreenshotFromWebView() throws {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let homeURL = URL(string: "https://example.com")
        let mockTabWebView = MockTabWebView(tab: tab)

        mockTabWebView.loadedURL = homeURL
        tab.webView = mockTabWebView
        tab.url = homeURL

        subject.takeScreenshot(tab, windowUUID: .XCTestDefaultUUID, screenshotBounds: .zero)

        let screenshotAction = try XCTUnwrap(
            mockStore.dispatchedActions.first as? ScreenshotAction,
            "fired action was not of the expected type"
        )

        XCTAssertTrue(mockTabWebView.takeSnapshotWasCalled)
        XCTAssertEqual(screenshotAction.tab, tab)
        XCTAssertFalse(tab.hasHomeScreenshot)
        XCTAssertIdentical(tab.screenshot,
                           mockTabWebView.mockSnapshotImage,
                           "The tab keeps the snapshot itself, so no full size copy is retained for its lifetime.")
    }

    func testTakeScreenshotFromWebView_persistsACopyTheProcessOwns() throws {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let homeURL = URL(string: "https://example.com")
        let mockTabWebView = MockTabWebView(tab: tab)

        mockTabWebView.loadedURL = homeURL
        tab.webView = mockTabWebView
        tab.url = homeURL

        subject.takeScreenshot(tab, windowUUID: .XCTestDefaultUUID, screenshotBounds: .zero)

        let screenshotAction = try XCTUnwrap(
            mockStore.dispatchedActions.first as? ScreenshotAction,
            "fired action was not of the expected type"
        )
        let persistedBacking = try XCTUnwrap(screenshotAction.screenshotToPersist?.cgImage)
        let sourceBacking = try XCTUnwrap(mockTabWebView.mockSnapshotImage.cgImage)

        XCTAssertFalse(persistedBacking === sourceBacking,
                       "Persisting draws the image off the main actor, so it must get a bitmap we own.")
        XCTAssertEqual(persistedBacking.width, sourceBacking.width)
        XCTAssertEqual(persistedBacking.height, sourceBacking.height)
    }

    private func createSubject() -> ScreenshotHelper {
        let subject = ScreenshotHelper(controller: mockVC)
        trackForMemoryLeaks(subject)
        return subject
    }

    func setupAppState() -> AppState {
        return AppState()
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
