// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import XCTest
import Glean
import Common
import Shared

@testable import Client

class BrowserViewControllerTests: XCTestCase, StoreTestUtility {
    var profile: MockProfile!
    var tabManager: MockTabManager!
    var screenshotHelper: MockScreenshotHelper!
    var browserCoordinator: MockBrowserCoordinator!
    var mockStore: MockStoreForMiddleware<AppState>!
    var appStartupTelemetry: MockAppStartupTelemetry!
    var appState: AppState!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        TelemetryContextualIdentifier.setupContextId()
        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)

        profile = MockProfile()
        tabManager = MockTabManager()
        browserCoordinator = MockBrowserCoordinator()
        appStartupTelemetry = MockAppStartupTelemetry()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        setupStore()
    }

    override func tearDown() {
        TelemetryContextualIdentifier.clearUserDefaults()
        profile.shutdown()
        profile = nil
        tabManager = nil
        appStartupTelemetry = nil
        Glean.shared.resetGlean(clearStores: true)
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func testTrackVisibleSuggestion() {
        let subject = createSubject()
        let expectation = expectation(description: "The Firefox Suggest ping was sent")

        GleanMetrics.Pings.shared.fxSuggest.testBeforeNextSubmit { _ in
            XCTAssertEqual(GleanMetrics.FxSuggest.pingType.testGetValue(), "fxsuggest-impression")
            XCTAssertEqual(
                GleanMetrics.FxSuggest.contextId.testGetValue()?.uuidString,
                TelemetryContextualIdentifier.contextId
            )
            XCTAssertEqual(GleanMetrics.FxSuggest.isClicked.testGetValue(), false)
            XCTAssertEqual(GleanMetrics.FxSuggest.position.testGetValue(), 3)
            XCTAssertEqual(GleanMetrics.FxSuggest.blockId.testGetValue(), 1)
            XCTAssertEqual(GleanMetrics.FxSuggest.advertiser.testGetValue(), "test advertiser")
            XCTAssertEqual(GleanMetrics.FxSuggest.iabCategory.testGetValue(), "999 - Test Category")
            XCTAssertEqual(GleanMetrics.FxSuggest.reportingUrl.testGetValue(), "https://example.com/ios_test_impression_reporting_url")
            expectation.fulfill()
        }

        subject.trackVisibleSuggestion(telemetryInfo: .firefoxSuggestion(
            RustFirefoxSuggestionTelemetryInfo.amp(
                blockId: 1,
                advertiser: "test advertiser",
                iabCategory: "999 - Test Category",
                impressionReportingURL: URL(string: "https://example.com/ios_test_impression_reporting_url"),
                clickReportingURL: URL(string: "https://example.com/ios_test_click_reporting_url")
            ),
            position: 3,
            didTap: false
        ))

        wait(for: [expectation], timeout: 5.0)
    }

    func testAppWillResignActiveNotification_takesScreenshot_ifNoViewIsPresented() {
        let subject = createSubject()
        tabManager.selectedTab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        subject.appWillResignActiveNotification()
        XCTAssertTrue(screenshotHelper.takeScreenshotCalled)
    }

    func testAppWillResignActiveNotification_doesNotTakeScreenshot_ifAViewIsPresented() {
        // Using the mock BVC here so we can "present" a view controller without loading it
        // into the window. The function under test `appWillResignActiveNotification` is not stubbed out
        let mockBVC = MockBrowserViewController(profile: profile, tabManager: tabManager)
        screenshotHelper = MockScreenshotHelper(controller: mockBVC)
        mockBVC.screenshotHelper = screenshotHelper
        mockBVC.viewControllerToPresent = UIViewController()
        tabManager.selectedTab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        mockBVC.appWillResignActiveNotification()
        XCTAssertFalse(screenshotHelper.takeScreenshotCalled)
    }

    func testOpenURLInNewTab_withPrivateModeEnabled() {
        let subject = createSubject()

        subject.openURLInNewTab(nil, isPrivate: true)
        XCTAssertTrue(tabManager.addTabWasCalled)
        XCTAssertNotNil(tabManager.selectedTab)
        guard let selectedTab = tabManager.selectedTab else {
            XCTFail("selected tab was nil")
            return
        }
        XCTAssertTrue(selectedTab.isPrivate)
    }

    func testDidSelectedTabChange_appliesExpectedUIModeToAllUIElements_whenToolbarRefactorDisabled() {
        let subject = createSubject()
        let topTabsViewController = TopTabsViewController(tabManager: tabManager, profile: profile)
        let testTab = Tab(profile: profile, isPrivate: true, windowUUID: .XCTestDefaultUUID)
        let mockTabWebView = MockTabWebView(tab: testTab)
        testTab.webView = mockTabWebView
        setupNimbusToolbarRefactorTesting(isEnabled: false)

        subject.topTabsViewController = topTabsViewController
        subject.tabManager(tabManager, didSelectedTabChange: testTab, previousTab: nil, isRestoring: false)

        XCTAssertEqual(topTabsViewController.privateModeButton.tintColor, DarkTheme().colors.iconOnColor)
        XCTAssertFalse(subject.toolbar.privateModeBadge.badge.isHidden)
    }

    func testDidSelectedTabChange_appliesExpectedUIModeToTopTabsViewController_whenToolbarRefactorEnabled() {
        let subject = createSubject()
        let topTabsViewController = TopTabsViewController(tabManager: tabManager, profile: profile)
        let testTab = Tab(profile: profile, isPrivate: true, windowUUID: .XCTestDefaultUUID)
        let mockTabWebView = MockTabWebView(tab: testTab)
        testTab.webView = mockTabWebView
        setupNimbusToolbarRefactorTesting(isEnabled: true)

        subject.topTabsViewController = topTabsViewController

        subject.tabManager(tabManager, didSelectedTabChange: testTab, previousTab: nil, isRestoring: false)

        XCTAssertEqual(topTabsViewController.privateModeButton.tintColor, DarkTheme().colors.iconOnColor)
        XCTAssertTrue(subject.toolbar.privateModeBadge.badge.isHidden)
    }

    func test_didSelectedTabChange_fromHomepageToHomepage_triggersAppropriateDispatchAction() throws {
        let subject = createSubject()
        let testTab = Tab(profile: profile, isPrivate: true, windowUUID: .XCTestDefaultUUID)
        testTab.url = URL(string: "internal://local/about/home")!
        let mockTabWebView = MockTabWebView(tab: testTab)
        testTab.webView = mockTabWebView
        setupNimbusHomepageRebuildForTesting(isEnabled: true)

        let expectation = XCTestExpectation(description: "General browser action is dispatched")
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        subject.tabManager(tabManager, didSelectedTabChange: testTab, previousTab: testTab, isRestoring: false)
        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions[2] as? GeneralBrowserAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 5)
        XCTAssertEqual(actionType, GeneralBrowserActionType.didSelectedTabChangeToHomepage)
    }

    // MARK: - Handle PDF

    func testHandlePDFDownloadRequest_doesntDocumentLoadingView_whenTabNotSelected() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let request = URLRequest(url: URL(fileURLWithPath: "test"))

        subject.handlePDFDownloadRequest(request: request, tab: tab, filename: "test")
        XCTAssertEqual(browserCoordinator.showDocumentLoadingCalled, 0)
    }

    func testHandlePDFDownloadRequest_showDocumentLoadingView_whenTabSelected() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let request = URLRequest(url: URL(fileURLWithPath: "test"))

        tabManager.selectedTab = tab
        subject.handlePDFDownloadRequest(request: request, tab: tab, filename: "test")

        XCTAssertEqual(browserCoordinator.showDocumentLoadingCalled, 1)
    }

    func testHandlePDFDownloadRequest_callsEnqueueDocumentOnTab() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let request = URLRequest(url: URL(fileURLWithPath: "test"))

        subject.handlePDFDownloadRequest(request: request, tab: tab, filename: "test")

        XCTAssertEqual(tab.enqueueDocumentCalled, 1)
        XCTAssertNotNil(tab.temporaryDocument)
    }

    // MARK: - Start At Home
    func test_browserDidBecomeActive_triggersAppropriateDispatchAction() throws {
        let subject = createSubject()
        let expectation = XCTestExpectation(description: "Start at home action is dispatched")
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        subject.browserDidBecomeActive()
        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? StartAtHomeAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? StartAtHomeActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, StartAtHomeActionType.didBrowserBecomeActive)
    }

    private func createSubject() -> BrowserViewController {
        let subject = BrowserViewController(profile: profile,
                                            tabManager: tabManager,
                                            appStartupTelemetry: appStartupTelemetry)
        screenshotHelper = MockScreenshotHelper(controller: subject)
        subject.screenshotHelper = screenshotHelper
        subject.navigationHandler = browserCoordinator
        trackForMemoryLeaks(subject)
        return subject
    }

    private func setupNimbusToolbarRefactorTesting(isEnabled: Bool) {
        FxNimbus.shared.features.toolbarRefactorFeature.with { _, _ in
            return ToolbarRefactorFeature(enabled: isEnabled)
        }
    }

    private func setupNimbusHomepageRebuildForTesting(isEnabled: Bool) {
        FxNimbus.shared.features.homepageRebuildFeature.with { _, _ in
            return HomepageRebuildFeature(enabled: isEnabled)
        }
    }

    // MARK: StoreTestUtility
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

class MockScreenshotHelper: ScreenshotHelper {
    var takeScreenshotCalled = false

    override func takeScreenshot(_ tab: Tab,
                                 windowUUID: WindowUUID,
                                 screenshotBounds: CGRect,
                                 completion: (() -> Void)? = nil) {
        takeScreenshotCalled = true
    }
}

class MockAppStartupTelemetry: AppStartupTelemetry {
    var sendStartupTelemetryCalled = 0

    func sendStartupTelemetry() {
        sendStartupTelemetryCalled += 1
    }
}
