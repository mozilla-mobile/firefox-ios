// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import Redux
import ToolbarKit
import XCTest

@testable import Client

final class ToolbarMiddlewareTests: XCTestCase, StoreTestUtility {
    let windowUUID: WindowUUID = .XCTestDefaultUUID
    var mockStore: MockStoreForMiddleware<AppState>!
    var toolbarManager: ToolbarManager!

    override func setUp() {
        super.setUp()

        // Due to changes allow certain custom pings to implement their own opt-out
        // independent of Glean, custom pings may need to be registered manually in
        // tests in order to put them in a state in which they can collect data.
        Glean.shared.registerPings(GleanMetrics.Pings.shared)
        Glean.shared.resetGlean(clearStores: true)

        DependencyHelperMock().bootstrapDependencies()
        toolbarManager = DefaultToolbarManager()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    // GeneralBrowserMiddlewareAction
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

    // MicrosurveyPromptMiddlewareAction
    // MicrosurveyPromptAction

    // ToolbarMiddlewareAction
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

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.homeButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.homeButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
    }

    func testDidTapButton_tapOnNewTabButton_dispatchesAddNewTab() throws {
        try didTapButton(buttonType: .newTab, expectedActionType: GeneralBrowserActionType.addNewTab)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.oneTapNewTabButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.oneTapNewTabButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
    }

    func testDidTapButton_tapOnQrCodeButton_dispatchesAddNewTab() throws {
        try didTapButton(buttonType: .qrCode, expectedActionType: GeneralBrowserActionType.showQRcodeReader)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.qrScanButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.qrScanButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
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

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.qrScanButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.qrScanButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
    }

    func testDidTapButton_tapOnBackButton_dispatchesNavigateBack() throws {
        try didTapButton(buttonType: .back, expectedActionType: GeneralBrowserActionType.navigateBack)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.backButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.backButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
    }

    func testDidTapButton_tapOnForwardButton_dispatchesNavigateForward() throws {
        try didTapButton(buttonType: .forward, expectedActionType: GeneralBrowserActionType.navigateForward)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.forwardButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.forwardButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
    }

    func testDidTapButton_tapOnTrackingProtectionButton_dispatchesShowTrackingProtectionDetails() throws {
        try didTapButton(
            buttonType: .trackingProtection,
            expectedActionType: GeneralBrowserActionType.showTrackingProtectionDetails)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.siteInfoButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.siteInfoButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
    }

    func testDidTapButton_tapOnReaderModeButton_dispatchesShowReaderModes() throws {
        try didTapButton(buttonType: .readerMode, expectedActionType: GeneralBrowserActionType.showReaderMode)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.readerModeButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.readerModeButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
        XCTAssertEqual(resultValue[0].extra?["enabled"], "false")
    }

    func testDidTapButton_tapOnReloadButton_dispatchesReloadWebsite() throws {
        try didTapButton(buttonType: .reload, expectedActionType: GeneralBrowserActionType.reloadWebsite)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.refreshButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.refreshButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
    }

    func testDidTapButton_tapOnStopLoadingButton_dispatchesStopLoadingWebsite() throws {
        try didTapButton(buttonType: .stopLoading, expectedActionType: GeneralBrowserActionType.stopLoadingWebsite)
    }

    func testDidTapButton_tapOnShareButton_dispatchesShowShare() throws {
        try didTapButton(buttonType: .share, expectedActionType: GeneralBrowserActionType.showShare)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.shareButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.shareButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
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

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.searchButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.searchButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
    }

    func testDidTapButton_tapOnDataClearanceButton_dispatchesClearData() throws {
        try didTapButton(buttonType: .dataClearance, expectedActionType: GeneralBrowserActionType.clearData)

        testEventMetricRecordingSuccess(metric: GleanMetrics.Toolbar.dataClearanceButtonTapped)
        let resultValue = try XCTUnwrap(GleanMetrics.Toolbar.dataClearanceButtonTapped.testGetValue())
        XCTAssertEqual(resultValue[0].extra?["is_private"], "false")
    }

    // ToolbarAction
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

    // MARK: - Helpers
    private func createSubject(manager: ToolbarManager) -> ToolbarMiddleware {
        return ToolbarMiddleware(manager: manager)
    }

    private func didTapButton(buttonType: ToolbarActionState.ActionType,
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
