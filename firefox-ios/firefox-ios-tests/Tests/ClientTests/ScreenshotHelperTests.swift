// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class ScreenshotHelperTests: XCTestCase, StoreTestUtility {
    var profile: MockProfile!
    let tabManager = MockTabManager()
    var mockVC: MockBrowserViewController!
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
        mockVC = MockBrowserViewController(profile: profile, tabManager: tabManager)
        setupStore()
    }

    override func tearDown() {
        profile.shutdown()
        profile = nil
        DependencyHelperMock().reset()
        mockVC = nil
        resetStore()
        super.tearDown()
    }

    func testTakeScreenshotForHomepage() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let homeURL = URL(string: "internal://local/about/home")
        let mockTabWebView = MockTabWebView(tab: tab)

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
    }

    func testTakeScreenshotFromWebView() {
        let subject = createSubject()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let homeURL = URL(string: "https://example.com")
        let mockTabWebView = MockTabWebView(tab: tab)

        mockTabWebView.loadedURL = homeURL
        tab.webView = mockTabWebView
        tab.url = homeURL

        subject.takeScreenshot(tab, windowUUID: .XCTestDefaultUUID, screenshotBounds: .zero)

        guard let screenshotAction = mockStore.dispatchedActions.first as? ScreenshotAction else {
            XCTFail("fired action was not of the expected type")
            return
        }

        XCTAssertTrue(mockTabWebView.takeSnapshotWasCalled)
        XCTAssertEqual(screenshotAction.tab, tab)
        XCTAssertEqual(tab.screenshot, UIImage.strokedCheckmark)
        XCTAssertFalse(tab.hasHomeScreenshot)
    }

    private func createSubject() -> ScreenshotHelper {
        return ScreenshotHelper(controller: mockVC)
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
