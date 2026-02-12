// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
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
    var recordVisitManager: MockRecordVisitObservationManager!

    override func setUp() async throws {
        try await super.setUp()
        setIsSwipingTabsEnabled(false)
        setIsHostedSummarizerEnabled(false)
        tabManager = MockTabManager()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: tabManager)

        profile = MockProfile()
        browserCoordinator = MockBrowserCoordinator()
        appStartupTelemetry = MockAppStartupTelemetry()
        recordVisitManager = MockRecordVisitObservationManager()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        setupStore()
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil
        tabManager = nil
        appStartupTelemetry = nil
        recordVisitManager = nil
        resetStore()
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testTrackVisibleSuggestion() {
        TelemetryContextualIdentifier.setupContextId()
        let subject = createSubject()
        let locale = MockLocaleProvider()
        let gleanWrapper = MockGleanWrapper()
        let telemetry = FxSuggestTelemetry(locale: locale, gleanWrapper: gleanWrapper)
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
        ), suggestTelemetry: telemetry)

        guard let savedPing = gleanWrapper.savedPing as? Ping<NoReasonCodes> else {
            XCTFail("savedPing is not of type Ping<NoReasonCodes>")
            return
        }
        XCTAssert(savedPing === GleanMetrics.Pings.shared.fxSuggest, "FxSuggest ping called")
        XCTAssertEqual(gleanWrapper.submitPingCalled, 1)
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

    @MainActor
    func testDidSelectedTabChange_appliesExpectedUIModeToTopTabsViewController() {
        let subject = createSubject()
        let topTabsViewController = TopTabsViewController(tabManager: tabManager, profile: profile)
        let testTab = Tab(profile: profile, isPrivate: true, windowUUID: .XCTestDefaultUUID)
        let mockTabWebView = MockTabWebView(tab: testTab)
        testTab.webView = mockTabWebView
        setupNimbusToolbarRefactorTesting(isEnabled: true)

        subject.topTabsViewController = topTabsViewController

        subject.tabManager(tabManager, didSelectedTabChange: testTab, previousTab: nil, isRestoring: false)

        XCTAssertEqual(topTabsViewController.privateModeButton.tintColor, DarkTheme().colors.iconOnColor)
    }

    func test_didSelectedTabChange_fromHomepageToHomepage_triggersAppropriateDispatchAction() throws {
        let subject = createSubject()
        let testTab = Tab(profile: profile, isPrivate: true, windowUUID: .XCTestDefaultUUID)
        testTab.url = URL(string: "internal://local/about/home")!
        let mockTabWebView = MockTabWebView(tab: testTab)
        testTab.webView = mockTabWebView

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

    func testUpdateReaderModeState_whenSummarizeFeatureOn_dispatchesToolbarMiddlewareAction() throws {
        setIsHostedSummarizerEnabled(true)
        let expectation = XCTestExpectation(description: "expect mock store to dispatch an action")
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.webView = MockTabWebView(tab: tab)

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        subject.updateReaderModeState(for: tab, readerModeState: .active)
        wait(for: [expectation])

        let action = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarMiddlewareAction)
        XCTAssertEqual(action.readerModeState, .active)
    }
    // TODO(FXIOS-13126): Fix and uncomment this test
//    func testUpdateReaderModeState_whenSummarizeFeatureOff_dispatchesToolbarAction() throws {
//        let expectation = XCTestExpectation(description: "expect mock store to dispatch an action")
//        let subject = createSubject()
//        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
//
//        mockStore.dispatchCalled = {
//            expectation.fulfill()
//        }
//        subject.updateReaderModeState(for: tab, readerModeState: .active)
//        wait(for: [expectation])
//
//        let action = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarMiddlewareAction)
//        XCTAssertEqual(action.readerModeState, .active)
//    }

    func testHandle_withoutURL_withSelectedTab_notRestoring_opensBlankNewTab_ifTabHasURL_and_isNotHomepage() {
        let mockBVC = MockBrowserViewController(profile: profile, tabManager: tabManager)
        tabManager.selectedTab = MockTab(
            profile: profile,
            isPrivate: false,
            windowUUID: .XCTestDefaultUUID,
            isHomePage: false
        )
        tabManager.isRestoringTabs = false
        tabManager.selectedTab?.url = URL(string: "https://example.com/")
        mockBVC.handle(url: nil, isPrivate: false, options: nil)
        XCTAssertTrue(mockBVC.openBlankNewTabCalled)
    }

    func testHandle_withoutURL_withSelectedTab_notRestoring_opensBlankNewTab_ifPrivateDoesNotMatch() {
        let mockBVC = MockBrowserViewController(profile: profile, tabManager: tabManager)
        tabManager.selectedTab = MockTab(
            profile: profile,
            isPrivate: false,
            windowUUID: .XCTestDefaultUUID,
            isHomePage: true
        )
        tabManager.isRestoringTabs = false
        mockBVC.handle(url: nil, isPrivate: true, options: nil)
        XCTAssertTrue(mockBVC.openBlankNewTabCalled)
    }

    func testShouldFocusLocationTextField_true_whenPrivateMatches_andIsFxHome() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, isPrivate: false, windowUUID: .XCTestDefaultUUID, isHomePage: true)
        XCTAssertTrue(subject.shouldFocusLocationTextField(for: tab, isPrivate: false))
    }

    func testShouldFocusLocationTextField_true_whenPrivateMatches_andUrlIsNil() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, isPrivate: false, windowUUID: .XCTestDefaultUUID, isHomePage: false)
        XCTAssertTrue(subject.shouldFocusLocationTextField(for: tab, isPrivate: false))
    }

    func testShouldFocusLocationTextField_false_whenPrivateMismatch() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, isPrivate: false, windowUUID: .XCTestDefaultUUID, isHomePage: false)
        XCTAssertFalse(subject.shouldFocusLocationTextField(for: tab, isPrivate: true))
    }

    func testShouldFocusLocationTextField_false_whenHasURL_andNotFxHome() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, isPrivate: true, windowUUID: .XCTestDefaultUUID, isHomePage: false)
        tab.url = URL(string: "https://example.com/")
        XCTAssertFalse(subject.shouldFocusLocationTextField(for: tab, isPrivate: true))
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

    // MARK: - Shake motion
    func testMotionEnded_withShakeGestureEnabled_showsSummaryPanel() throws {
        profile.prefs.setBool(true, forKey: PrefsKeys.Summarizer.shakeGestureEnabled)
        setupSummarizedShakeGestureForTesting(isEnabled: true)
        let subject = createSubject()
        let expectation = XCTestExpectation(description: "General browser action is dispatched")
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        tabManager.selectedTab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        subject.motionEnded(.motionShake, with: nil)
        wait(for: [expectation], timeout: 1)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? GeneralBrowserAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, GeneralBrowserActionType.shakeMotionEnded)
    }

    func testMotionEnded_withShakeGestureDisabled_doesNotShowSummaryPanel() async {
        profile.prefs.setBool(false, forKey: PrefsKeys.Summarizer.shakeGestureEnabled)
        setupSummarizedShakeGestureForTesting(isEnabled: false)
        let subject = createSubject()
        tabManager.selectedTab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        subject.motionEnded(.motionShake, with: nil)
        try? await Task.sleep(nanoseconds: 100_000_000)
        let showSummarizerWasDispatched = mockStore.dispatchedActions.contains { action in
            guard let action = action as? GeneralBrowserAction,
                  let actionType = action.actionType as? GeneralBrowserActionType else { return false }
            if case .showSummarizer = actionType { return true }
            return false
        }
        XCTAssertFalse(showSummarizerWasDispatched)
    }

    func testMotionEnded_withGestureNotShake_doesntShowSummarizePanel() {
        let subject = createSubject()

        subject.motionEnded(.remoteControlBeginSeekingBackward, with: nil)

        XCTAssertEqual(browserCoordinator.showSummarizePanelCalled, 0)
    }
    // MARK: - Zero Search State

    func test_tapOnHomepageSearchBarAction_withBVCState_triggersGeneralBrowserAction() throws {
        let subject = createSubject()

        let newState = BrowserViewControllerState.reducer(
            BrowserViewControllerState(windowUUID: .XCTestDefaultUUID),
            NavigationBrowserAction(
                navigationDestination: NavigationDestination(.homepageZeroSearch),
                windowUUID: .XCTestDefaultUUID,
                actionType: NavigationBrowserActionType.tapOnHomepageSearchBar
            )
        )
        subject.newState(state: newState)

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.first(where: { $0 is GeneralBrowserAction }) as? GeneralBrowserAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)
        XCTAssertEqual(actionType, GeneralBrowserActionType.enteredZeroSearchScreen)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_didTapButtonToolbarAction_withHomepageSearch_andSearchButtonType_triggersGeneralBrowserAction() throws {
        setupStoreForSearchBar()
        let subject = createSubject()

        let newState = BrowserViewControllerState.reducer(
            BrowserViewControllerState(windowUUID: .XCTestDefaultUUID),
            ToolbarMiddlewareAction(
                buttonType: .search,
                windowUUID: .XCTestDefaultUUID,
                actionType: ToolbarMiddlewareActionType.didTapButton
            )
        )
        subject.newState(state: newState)

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.first(where: { $0 is GeneralBrowserAction }) as? GeneralBrowserAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)
        XCTAssertEqual(actionType, GeneralBrowserActionType.enteredZeroSearchScreen)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_didTapButtonToolbarAction_withHomepageSearch_andNoSearchButtonType_triggersGeneralBrowserAction() {
        setupStoreForSearchBar()
        let subject = createSubject()

        let newState = BrowserViewControllerState.reducer(
            BrowserViewControllerState(windowUUID: .XCTestDefaultUUID),
            ToolbarMiddlewareAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: ToolbarMiddlewareActionType.didTapButton
            )
        )
        subject.newState(state: newState)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    func test_didTapButtonToolbarAction_withoutHomepageSearch_andSearchButtonType_doesNotTriggersGeneralBrowserAction() {
        let subject = createSubject()

        let newState = BrowserViewControllerState.reducer(
            BrowserViewControllerState(windowUUID: .XCTestDefaultUUID),
            ToolbarMiddlewareAction(
                buttonType: .search,
                windowUUID: .XCTestDefaultUUID,
                actionType: ToolbarMiddlewareActionType.didTapButton
            )
        )
        subject.newState(state: newState)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    func test_didTapButtonToolbarAction_withoutHomepageSearch_andNoSearchButtonType_doesNotTriggersGeneralBrowserAction() {
        let subject = createSubject()

        let newState = BrowserViewControllerState.reducer(
            BrowserViewControllerState(windowUUID: .XCTestDefaultUUID),
            ToolbarMiddlewareAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: ToolbarMiddlewareActionType.didTapButton
            )
        )
        subject.newState(state: newState)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    func testNewState_whenSummarizeDisplayRequested() {
        let subject = createSubject()

        let newState = BrowserViewControllerState.reducer(
            BrowserViewControllerState(windowUUID: .XCTestDefaultUUID),
            GeneralBrowserAction(windowUUID: .XCTestDefaultUUID,
                                 actionType: GeneralBrowserActionType.showSummarizer)
        )
        subject.newState(state: newState)

        XCTAssertEqual(browserCoordinator.showSummarizePanelCalled, 1)
    }

    func testWillNavigateAway_withValidTab_takesScreenshotAsynchronously() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let expectation = XCTestExpectation(description: "Screenshot should be taken asynchronously")

        screenshotHelper.onTakeScreenshot = {
            expectation.fulfill()
        }

        subject.willNavigateAway(from: tab)

        // Screenshot should not be taken immediately due to async dispatch
        XCTAssertFalse(screenshotHelper.takeScreenshotCalled)

        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(screenshotHelper.takeScreenshotCalled)
    }

    func testWillNavigateAway_withNilTab_doesNotTakeScreenshot() {
        let subject = createSubject()

        subject.willNavigateAway(from: nil)

        XCTAssertFalse(screenshotHelper.takeScreenshotCalled)
    }

    // MARK: - Record visit observation for History Panel

    func testRecordVisitObservationIsCalledForNavigateInNewTabWithTitle() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        let url = URL(string: "https://example.com/")
        mockTabWebView.loadedURL = url
        tab.webView = mockTabWebView

        subject.navigateInTab(tab: tab, to: nil, webViewStatus: .title)

        XCTAssertEqual(recordVisitManager.recordVisitCalled, 1)
        XCTAssertNotNil(recordVisitManager.lastVisitObservation)
    }

    func testRecordVisitObservationIsCalledForNavigateInNewTabWithURL() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        let url = URL(string: "https://example.com/")
        mockTabWebView.loadedURL = url
        tab.webView = mockTabWebView

        subject.navigateInTab(tab: tab, to: nil, webViewStatus: .url)

        XCTAssertEqual(recordVisitManager.recordVisitCalled, 1)
        XCTAssertNotNil(recordVisitManager.lastVisitObservation)
    }

    func testRecordVisitObservationIsNotCalledForInternalURL() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        let url = URL(string: "http://localhost:\(AppInfo.webserverPort)/")
        mockTabWebView.loadedURL = url
        tab.webView = mockTabWebView

        subject.navigateInTab(tab: tab, to: nil, webViewStatus: .title)

        XCTAssertEqual(recordVisitManager.recordVisitCalled, 0)
        XCTAssertNil(recordVisitManager.lastVisitObservation)
    }

    func testRecordVisitObservationIsNotCalledForFileURL() {
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let mockTabWebView = MockTabWebView(tab: tab)
        let url = URL(fileURLWithPath: "/tmp/test.html")
        mockTabWebView.loadedURL = url
        tab.webView = mockTabWebView

        subject.navigateInTab(tab: tab, to: nil, webViewStatus: .title)

        XCTAssertEqual(recordVisitManager.recordVisitCalled, 0)
        XCTAssertNil(recordVisitManager.lastVisitObservation)
    }

    func testResetObservationIsCalledForAddNewTabAction() throws {
        let subject = createSubject()

        let action = GeneralBrowserAction(windowUUID: .XCTestDefaultUUID,
                                          actionType: GeneralBrowserActionType.addNewTab)
        let newState = BrowserViewControllerState.reducer(
            BrowserViewControllerState(windowUUID: .XCTestDefaultUUID), action)
        subject.newState(state: newState)

        XCTAssertEqual(recordVisitManager.resetVisitCalled, 1)
        XCTAssertNil(recordVisitManager.lastVisitObservation)
    }

    // MARK: - Private

    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> BrowserViewController {
        let subject = BrowserViewController(profile: profile,
                                            tabManager: tabManager,
                                            appStartupTelemetry: appStartupTelemetry,
                                            recordVisitManager: recordVisitManager)
        screenshotHelper = MockScreenshotHelper(controller: subject)
        subject.screenshotHelper = screenshotHelper
        subject.navigationHandler = browserCoordinator
        subject.browserDelegate = browserCoordinator

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func setupNimbusToolbarRefactorTesting(isEnabled: Bool) {
        FxNimbus.shared.features.toolbarRefactorFeature.with { _, _ in
            return ToolbarRefactorFeature(enabled: isEnabled)
        }
    }

    private func setIsSwipingTabsEnabled(_ isEnabled: Bool) {
        FxNimbus.shared.features.toolbarRefactorFeature.with { _, _ in
            return ToolbarRefactorFeature(swipingTabs: isEnabled)
        }
    }

    private func setIsHostedSummarizerEnabled(_ isEnabled: Bool) {
        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isEnabled)
        }
    }

    private func setupSummarizedShakeGestureForTesting(isEnabled: Bool) {
        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isEnabled, shakeGesture: isEnabled)
        }
    }

    /// We need to set up the state for the homepage search bar in order to test method that relies on this state.
    func setupStoreForSearchBar() {
        let initialHomepageState = HomepageState
            .reducer(
                HomepageState(windowUUID: .XCTestDefaultUUID),
                HomepageAction(
                    windowUUID: .XCTestDefaultUUID,
                    actionType: HomepageActionType.initialize
                )
            )
        let newHomepageState = HomepageState
            .reducer(
                initialHomepageState,
                HomepageAction(
                    isSearchBarEnabled: true,
                    windowUUID: .XCTestDefaultUUID,
                    actionType: HomepageMiddlewareActionType.configuredSearchBar
                )
            )
        mockStore = MockStoreForMiddleware(state: AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    ),
                    .homepage(
                        newHomepageState
                    )
                ]
            )
        ))
        StoreTestUtilityHelper.setupStore(with: mockStore)
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

class MockScreenshotHelper: ScreenshotHelper {
    var takeScreenshotCalled = false
    var onTakeScreenshot: (() -> Void)?

    override func takeScreenshot(_ tab: Tab,
                                 windowUUID: WindowUUID,
                                 screenshotBounds: CGRect) {
        takeScreenshotCalled = true
        onTakeScreenshot?()
    }
}

class MockAppStartupTelemetry: AppStartupTelemetry {
    var sendStartupTelemetryCalled = 0

    func sendStartupTelemetry() {
        sendStartupTelemetryCalled += 1
    }
}
