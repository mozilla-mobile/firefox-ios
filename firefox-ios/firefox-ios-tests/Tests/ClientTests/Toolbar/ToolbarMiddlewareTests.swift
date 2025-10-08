// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Redux
import ToolbarKit
import Shared
import XCTest

@testable import Client

final class ToolbarMiddlewareTests: XCTestCase, StoreTestUtility {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    var mockStore: MockStoreForMiddleware<AppState>!
    var toolbarManager: ToolbarManager!
    var mockGleanWrapper: MockGleanWrapper!
    var summarizationChecker: MockSummarizationChecker!
    var mockRecentSearchProvider: MockRecentSearchProvider!
    var windowManager: MockWindowManager!
    var tabManager: MockTabManager!
    var profile: MockProfile!

    override func setUp() {
        super.setUp()
        setIsHostedSummaryEnabled(false)
        mockGleanWrapper = MockGleanWrapper()
        summarizationChecker = MockSummarizationChecker()
        mockRecentSearchProvider = MockRecentSearchProvider()
        tabManager = MockTabManager()
        profile = MockProfile()
        windowManager = MockWindowManager(wrappedManager: WindowManagerImplementation(), tabManager: tabManager)
        DependencyHelperMock().bootstrapDependencies(injectedWindowManager: windowManager,
                                                     injectedTabManager: tabManager)
        toolbarManager = DefaultToolbarManager()

        // We must reset the global mock store prior to each test
        setupStore()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        mockGleanWrapper = nil
        summarizationChecker = nil
        mockRecentSearchProvider = nil
        tabManager = nil
        profile = nil
        windowManager = nil
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    // MARK: GeneralBrowserMiddlewareAction
    func testBrowserDidLoad_dispatchesDidLoadToolbars() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = GeneralBrowserMiddlewareAction(
            toolbarPosition: .top,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.browserDidLoad)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        let borderPosition = toolbarManager.getAddressBorderPosition(for: .top, isPrivate: false, scrollY: 0)
        let displayBorder = toolbarManager.shouldDisplayNavigationBorder(toolbarPosition: .top)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.didLoadToolbars)
        XCTAssertEqual(actionCalled.toolbarPosition, action.toolbarPosition)
        XCTAssertEqual(actionCalled.addressBorderPosition, borderPosition)
        XCTAssertEqual(actionCalled.displayNavBorder, displayBorder)
        XCTAssertEqual(actionCalled.middleButton, .newTab)
    }

    func testBrowserDidLoad_withHomeCustomMiddleButton_dispatchesDidLoadToolbars() throws {
        profile.prefs.setString(NavigationBarMiddleButtonType.home.rawValue,
                                forKey: PrefsKeys.Settings.navigationToolbarMiddleButton)
        let subject = createSubject(manager: toolbarManager)
        let action = GeneralBrowserMiddlewareAction(
            toolbarPosition: .top,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.browserDidLoad)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        let borderPosition = toolbarManager.getAddressBorderPosition(for: .top, isPrivate: false, scrollY: 0)
        let displayBorder = toolbarManager.shouldDisplayNavigationBorder(toolbarPosition: .top)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.didLoadToolbars)
        XCTAssertEqual(actionCalled.toolbarPosition, action.toolbarPosition)
        XCTAssertEqual(actionCalled.addressBorderPosition, borderPosition)
        XCTAssertEqual(actionCalled.displayNavBorder, displayBorder)
        XCTAssertEqual(actionCalled.middleButton, .home)
    }

    func testWebsiteDidScroll_dispatchesBorderPositionChanged() throws {
        let scrollOffset = CGPoint(x: 0, y: 100)
        let subject = createSubject(manager: toolbarManager)
        let action = GeneralBrowserMiddlewareAction(
            scrollOffset: scrollOffset,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.websiteDidScroll)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        let borderPosition = toolbarManager.getAddressBorderPosition(for: .top,
                                                                     isPrivate: false,
                                                                     scrollY: scrollOffset.y)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.borderPositionChanged)
        XCTAssertEqual(actionCalled.toolbarPosition, action.toolbarPosition)
        XCTAssertEqual(actionCalled.addressBorderPosition, borderPosition)
    }

    func testToolbarPositionChanged_dispatchesToolbarPositionChanged() throws {
        let scrollOffset = CGPoint(x: 0, y: 100)
        let subject = createSubject(manager: toolbarManager)
        let action = GeneralBrowserMiddlewareAction(
            scrollOffset: scrollOffset,
            toolbarPosition: .bottom,
            windowUUID: windowUUID,
            actionType: GeneralBrowserMiddlewareActionType.toolbarPositionChanged)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        let borderPosition = toolbarManager.getAddressBorderPosition(for: .bottom,
                                                                     isPrivate: false,
                                                                     scrollY: scrollOffset.y)
        let displayBorder = toolbarManager.shouldDisplayNavigationBorder(toolbarPosition: .bottom)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.toolbarPositionChanged)
        XCTAssertEqual(actionCalled.toolbarPosition, action.toolbarPosition)
        XCTAssertEqual(actionCalled.addressBorderPosition, borderPosition)
        XCTAssertEqual(actionCalled.displayNavBorder, displayBorder)
    }

    func testLoadSummary_whenWebViewIsNil_doesntDispatchToolbarAction() {
        setIsHostedSummaryEnabled(true)
        let subject = createSubject(manager: toolbarManager)

        let action = ToolbarMiddlewareAction(readerModeState: .active,
                                             windowUUID: .XCTestDefaultUUID,
                                             actionType: ToolbarMiddlewareActionType.loadSummaryState)
        subject.toolbarProvider(mockStore.state, action)

        XCTAssertNil(mockStore.dispatchedActions.first as? ToolbarAction)
    }

    func testLoadSummary_dispatchesToolbarAction() throws {
        setIsHostedSummaryEnabled(true)
        let expectation = XCTestExpectation(description: "Store should dispatch an action")
        let subject = createSubject(manager: toolbarManager)
        let tab = MockTab(profile: MockProfile(), windowUUID: .XCTestDefaultUUID)
        tab.webView = MockTabWebView(tab: tab)
        tabManager.selectedTab = tab

        let action = ToolbarMiddlewareAction(readerModeState: .active,
                                             windowUUID: .XCTestDefaultUUID,
                                             actionType: ToolbarMiddlewareActionType.loadSummaryState)
        summarizationChecker.overrideResponse = MockSummarizationChecker.success
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }
        subject.toolbarProvider(mockStore.state, action)
        wait(for: [expectation])

        let result = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        XCTAssertTrue(result.canSummarize)
    }

    // MARK: - MicrosurveyPromptMiddlewareAction
    func testMicrosurveyPromptInitialize_withTopToolbar_dispatchesToolbarPositionChanged() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = MicrosurveyPromptMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.initialize)
        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.borderPositionChanged)
        XCTAssertEqual(actionCalled.displayNavBorder, false)
    }

    func testMicrosurveyPromptInitialize_withBottomToolbar_dispatchesToolbarPositionChanged() throws {
        mockStore = MockStoreForMiddleware(state: setupToolbarBottomPositionAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)

        let subject = createSubject(manager: toolbarManager)
        let action = MicrosurveyPromptMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.initialize)
        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.borderPositionChanged)
        XCTAssertEqual(actionCalled.addressBorderPosition, AddressToolbarBorderPosition.none)
        XCTAssertEqual(actionCalled.displayNavBorder, false)
    }

    // MARK: - MicrosurveyPromptAction
    func testMicrosurveyPromptClosePrompt_withTopToolbar_dispatchesToolbarPositionChanged() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = MicrosurveyPromptAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptActionType.closePrompt)
        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.borderPositionChanged)
        XCTAssertEqual(actionCalled.displayNavBorder, true)
    }

    func testMicrosurveyPromptClosePrompt_withBottomToolbar_dispatchesToolbarPositionChanged() throws {
        mockStore = MockStoreForMiddleware(state: setupToolbarBottomPositionAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)

        let subject = createSubject(manager: toolbarManager)
        let action = MicrosurveyPromptAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptActionType.closePrompt)
        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.borderPositionChanged)
        XCTAssertEqual(actionCalled.addressBorderPosition, AddressToolbarBorderPosition.top)
        XCTAssertEqual(actionCalled.displayNavBorder, false)
    }

    // MARK: - ToolbarMiddlewareAction
    func testCustomA11yAction_dispatchesAddToReadingListLongPressAction() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            buttonType: .readerMode,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.customA11yAction)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? GeneralBrowserAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, GeneralBrowserActionType.addToReadingListLongPressAction)
    }

    func testDidTapButton_tapOnHomeButton_dispatchesGoToHomepage() throws {
        try didTapButton(buttonType: .home, expectedActionType: GeneralBrowserActionType.goToHomepage)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.HomeButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.HomeButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.homeButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnNewTabButton_dispatchesAddNewTab() throws {
        try didTapButton(buttonType: .newTab, expectedActionType: GeneralBrowserActionType.addNewTab)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.OneTapNewTabButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.OneTapNewTabButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.oneTapNewTabButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnQrCodeButton_dispatchesAddNewTab() throws {
        try didTapButton(buttonType: .qrCode, expectedActionType: GeneralBrowserActionType.showQRcodeReader)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.QrScanButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.QrScanButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.qrScanButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnQrCodeButton_whenInEditMode_dispatchesCancelEditAndAddNewTab() throws {
        mockStore = MockStoreForMiddleware(state: setupEditingAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)

        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            buttonType: .qrCode,
            gestureType: .tap,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton)

        subject.toolbarProvider(mockStore.state, action)

        let firstActionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstActionCalled.actionType as? ToolbarActionType)
        let secondActionCalled = try XCTUnwrap(mockStore.dispatchedActions.last as? GeneralBrowserAction)
        let secondActionType = try XCTUnwrap(secondActionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 2)
        XCTAssertEqual(firstActionType, ToolbarActionType.cancelEdit)
        XCTAssertEqual(secondActionType, GeneralBrowserActionType.showQRcodeReader)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.QrScanButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.QrScanButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.qrScanButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnBackButton_dispatchesNavigateBack() throws {
        try didTapButton(buttonType: .back, expectedActionType: GeneralBrowserActionType.navigateBack)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.BackButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.BackButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.backButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnForwardButton_dispatchesNavigateForward() throws {
        try didTapButton(buttonType: .forward, expectedActionType: GeneralBrowserActionType.navigateForward)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.ForwardButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.ForwardButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.forwardButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnTabsButton_dispatchesShowTabTray() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            buttonType: .tabs,
            gestureType: .tap,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton)

        subject.toolbarProvider(mockStore.state, action)

        try cancelEditMode(dispatchedActionsCount: 3)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.last as? GeneralBrowserAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(actionType, GeneralBrowserActionType.showTabTray)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.TabTrayButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.TabTrayButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.tabTrayButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnTrackingProtectionButton_dispatchesShowTrackingProtectionDetails() throws {
        try didTapButton(
            buttonType: .trackingProtection,
            expectedActionType: GeneralBrowserActionType.showTrackingProtectionDetails)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.SiteInfoButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.SiteInfoButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.siteInfoButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnMenuButton_dispatchesShowMenu() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            buttonType: .menu,
            buttonTapped: UIButton(),
            gestureType: .tap,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton)

        subject.toolbarProvider(mockStore.state, action)

        try cancelEditMode(dispatchedActionsCount: 3)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.last as? GeneralBrowserAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(actionType, GeneralBrowserActionType.showMenu)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.AppMenuButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.AppMenuButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.appMenuButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnCancelEditButton_dispatchesShowMenu() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            buttonType: .cancelEdit,
            gestureType: .tap,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton)

        subject.toolbarProvider(mockStore.state, action)

        try cancelEditMode(dispatchedActionsCount: 2)
    }

    func testDidTapButton_tapOnReaderModeButton_dispatchesShowReaderModes() throws {
        try didTapButton(buttonType: .readerMode, expectedActionType: GeneralBrowserActionType.showReaderMode)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.ReaderModeButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.ReaderModeButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.readerModeButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
        XCTAssertEqual(savedExtras.enabled, false)
    }

    func testDidTapButton_tapOnReloadButton_dispatchesReloadWebsite() throws {
        try didTapButton(buttonType: .reload, expectedActionType: GeneralBrowserActionType.reloadWebsite)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.RefreshButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.RefreshButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.refreshButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnStopLoadingButton_dispatchesStopLoadingWebsite() throws {
        try didTapButton(buttonType: .stopLoading, expectedActionType: GeneralBrowserActionType.stopLoadingWebsite)
    }

    func testDidTapButton_tapOnShareButton_dispatchesShowShare() throws {
        try didTapButton(buttonType: .share, expectedActionType: GeneralBrowserActionType.showShare)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.ShareButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.ShareButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.shareButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnSearchButton_dispatchesDidStartEditingUrl() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            buttonType: .search,
            gestureType: .tap,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.didStartEditingUrl)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.SearchButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.SearchButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.searchButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_tapOnDataClearanceButton_dispatchesClearData() throws {
        try didTapButton(buttonType: .dataClearance, expectedActionType: GeneralBrowserActionType.clearData)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.DataClearanceButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.DataClearanceButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.dataClearanceButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }
    // TODO(FXIOS-13126): Fix and uncomment this test
//    func testDidTapButton_tapOnSummarizerButton_dispatchesShowSummarizer() throws {
//        try didTapButton(buttonType: .summarizer, expectedActionType: .showSummarizer)
//    }

    func testDidTapButton_longPressOnBackButton_dispatchesShowBackForwardList() throws {
        try didLongPressButton(buttonType: .back, expectedActionType: GeneralBrowserActionType.showBackForwardList)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.BackLongPressExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.BackLongPressExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.backLongPress)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_longPressOnForwardButton_dispatchesShowBackForwardList() throws {
        try didLongPressButton(buttonType: .forward, expectedActionType: GeneralBrowserActionType.showBackForwardList)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.ForwardLongPressExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.ForwardLongPressExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.forwardLongPress)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_longPressOnTabsButton_dispatchesShowTabsLongPressActions() throws {
        try didLongPressButton(buttonType: .tabs, expectedActionType: GeneralBrowserActionType.showTabsLongPressActions)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.TabTrayLongPressExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.TabTrayLongPressExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.tabTrayLongPress)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_longPressOnLocationView_dispatchesShowLocationViewLongPressActionSheet() throws {
        try didLongPressButton(buttonType: .locationView,
                               expectedActionType: GeneralBrowserActionType.showLocationViewLongPressActionSheet)
    }

    func testDidTapButton_longPressOnReloadButton_dispatchesShowReloadLongPressAction() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            buttonType: .reload,
            buttonTapped: UIButton(),
            gestureType: .longPress,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? GeneralBrowserAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, GeneralBrowserActionType.showReloadLongPressAction)
    }

    func testDidTapButton_longPressOnNewTabButton_dispatchesShowNewTabLongPressActions() throws {
        try didLongPressButton(buttonType: .newTab,
                               expectedActionType: GeneralBrowserActionType.showNewTabLongPressActions)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.OneTapNewTabLongPressExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.OneTapNewTabLongPressExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.oneTapNewTabLongPress)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidTapButton_longPressOnReaderMode_dispatchesAddToReadingListLongPressAction() throws {
        try didLongPressButton(buttonType: .readerMode,
                               expectedActionType: GeneralBrowserActionType.addToReadingListLongPressAction)
    }

    func testDidTapButton_longPressOnSummarizer_dispatchesShowReaderModeAction() throws {
        try didLongPressButton(buttonType: .summarizer, expectedActionType: .showReaderMode)
    }

    func testUrlDidChange_dispatchesBorderPositionChanged() throws {
        let scrollOffset = CGPoint(x: 0, y: 100)
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            scrollOffset: scrollOffset,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.urlDidChange)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)
        let borderPosition = toolbarManager.getAddressBorderPosition(for: .top,
                                                                     isPrivate: false,
                                                                     scrollY: scrollOffset.y)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.borderPositionChanged)
        XCTAssertEqual(actionCalled.addressBorderPosition, borderPosition)
    }

    func testDidClearSearch_dispatchesClearSearch() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didClearSearch)
        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? ToolbarActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, ToolbarActionType.clearSearch)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Toolbar.ClearSearchButtonTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Toolbar.ClearSearchButtonTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Toolbar.clearSearchButtonTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isPrivate, false)
    }

    func testDidStartDragInteraction_recordsTelemetry() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didStartDragInteraction)
        subject.toolbarProvider(mockStore.state, action)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>
        )
        let expectedMetricType = type(of: GleanMetrics.Awesomebar.dragLocationBar)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    // MARK: - ToolbarAction
    func testCancelEdit_dispatchesDidClearAlternativeSearchEngine() throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarAction(
            windowUUID: windowUUID,
            actionType: ToolbarActionType.cancelEdit)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? SearchEngineSelectionAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? SearchEngineSelectionMiddlewareActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, SearchEngineSelectionMiddlewareActionType.didClearAlternativeSearchEngine)
    }

    func test_didSubmitSearchTerm_withProperPayload_addsRecentSearchToHistoryStorage() {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarAction(
            url: URL(string: "https://example.com")!,
            searchTerm: "cookies",
            windowUUID: windowUUID,
            actionType: ToolbarActionType.didSubmitSearchTerm
        )

        subject.toolbarProvider(mockStore.state, action)
        XCTAssertEqual(mockRecentSearchProvider.addRecentSearchCalledCount, 1)
    }

    func test_didSubmitSearchTerm_withoutURL_doesNotAddRecentSearchToHistoryStorage() {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarAction(
            searchTerm: "cookies",
            windowUUID: windowUUID,
            actionType: ToolbarActionType.didSubmitSearchTerm
        )

        subject.toolbarProvider(mockStore.state, action)
        XCTAssertEqual(mockRecentSearchProvider.addRecentSearchCalledCount, 0)
    }

    func test_didSubmitSearchTerm_withoutSearchTerm_doesNotAddRecentSearchToHistoryStorage() {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarAction(
            windowUUID: windowUUID,
            actionType: ToolbarActionType.didSubmitSearchTerm
        )

        subject.toolbarProvider(mockStore.state, action)
        XCTAssertEqual(mockRecentSearchProvider.addRecentSearchCalledCount, 0)
    }

    // MARK: - Helpers
    private func createSubject(manager: ToolbarManager) -> ToolbarMiddleware {
        return ToolbarMiddleware(
            manager: manager,
            toolbarTelemetry: ToolbarTelemetry(gleanWrapper: mockGleanWrapper),
            profile: profile,
            summarizationChecker: summarizationChecker,
            recentSearchProvider: mockRecentSearchProvider,
            windowManager: windowManager
        )
    }

    private func didTapButton(buttonType: ToolbarActionConfiguration.ActionType,
                              expectedActionType: GeneralBrowserActionType) throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            buttonType: buttonType,
            gestureType: .tap,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? GeneralBrowserAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, expectedActionType)
    }

    private func didLongPressButton(buttonType: ToolbarActionConfiguration.ActionType,
                                    expectedActionType: GeneralBrowserActionType) throws {
        let subject = createSubject(manager: toolbarManager)
        let action = ToolbarMiddlewareAction(
            buttonType: buttonType,
            gestureType: .longPress,
            windowUUID: windowUUID,
            actionType: ToolbarMiddlewareActionType.didTapButton)

        subject.toolbarProvider(mockStore.state, action)

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? GeneralBrowserAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionType, expectedActionType)
    }

    private func cancelEditMode(dispatchedActionsCount: Int = 2) throws {
        let firstActionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? ToolbarAction)
        let firstActionType = try XCTUnwrap(firstActionCalled.actionType as? ToolbarActionType)
        let secondActionCalled = try XCTUnwrap(mockStore.dispatchedActions[1] as? GeneralBrowserAction)
        let secondActionType = try XCTUnwrap(secondActionCalled.actionType as? GeneralBrowserActionType)

        XCTAssertEqual(mockStore.dispatchedActions.count, dispatchedActionsCount)
        XCTAssertEqual(firstActionType, ToolbarActionType.cancelEdit)
        XCTAssertEqual(secondActionType, GeneralBrowserActionType.leaveOverlay)
    }

    private func setIsHostedSummaryEnabled(_ isEnabled: Bool) {
        return FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isEnabled)
        }
    }

    func setupEditingAppState() -> AppState {
        var addressBarState = AddressBarState(windowUUID: windowUUID)
        addressBarState.isEditing = true
        var toolbarState = ToolbarState(windowUUID: windowUUID)
        toolbarState.addressToolbar = addressBarState

        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: windowUUID
                        )
                    ),
                    .toolbar(toolbarState)
                ]
            )
        )
    }

    func setupToolbarBottomPositionAppState() -> AppState {
        var toolbarState = ToolbarState(windowUUID: windowUUID)
        toolbarState.toolbarPosition = .bottom

        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: windowUUID
                        )
                    ),
                    .toolbar(toolbarState)
                ]
            )
        )
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .browserViewController(
                        BrowserViewControllerState(
                            windowUUID: windowUUID
                        )
                    ),
                    .toolbar(
                        ToolbarState(
                            windowUUID: windowUUID
                        )
                    )
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
