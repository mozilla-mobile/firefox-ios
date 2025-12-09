// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class MainMenuMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockGleanWrapper: MockGleanWrapper!
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        mockGleanWrapper = MockGleanWrapper()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        mockGleanWrapper = nil
        resetStore()
        try await super.tearDown()
    }

    func test_tapNavigateToDestination_findInPageAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .findInPage)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "find_in_page")
    }

    func test_tapNavigateToDestination_bookmarksAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .bookmarks)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "bookmarks")
    }

    func test_tapNavigateToDestination_historyAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .history)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "history")
    }

    func test_tapNavigateToDestination_downloadsAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .downloads)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "downloads")
    }

    func test_tapNavigateToDestination_passwordsAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .passwords)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "passwords")
    }

    func test_tapNavigateToDestination_settingsAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .settings)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "settings")
    }

    func test_tapNavigateToDestination_printSheetAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .printSheet)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "print")
    }

    func test_tapNavigateToDestination_shareSheetAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .shareSheet)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "share")
    }

    func test_tapNavigateToDestination_saveAsPDFAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .saveAsPDF)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "save_as_PDF")
    }

    func test_tapNavigateToDestination_syncSignInAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .syncSignIn)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "sign_in_account")
    }

    func test_tapNavigateToDestination_editBookmarkAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .editBookmark)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "edit_bookmark")
    }

    func test_tapNavigateToDestination_zoomAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .zoom)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "zoom")
    }

    func test_tapNavigateToDestination_siteProtectionsAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .siteProtections)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "site_protections")
    }

    func test_tapNavigateToDestination_defaultBrowserAction_sendTelemetryData() throws {
        let action = getNavigationDestinationAction(for: .defaultBrowser)
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "default_browser_settings")
    }

    func test_tapToggleUserAgentAction_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapToggleUserAgent,
            telemetryInfo: TelemetryInfo(isHomepage: false, isDefaultUserAgentDesktop: false, hasChangedUserAgent: true)
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "switch_to_mobile_site")
    }

    func test_tapCloseMenuAction_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapCloseMenu
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.CloseButtonExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.CloseButtonExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.closeButton)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isHomepage, false)
    }

    func test_didInstantiateViewAction_updateBannerVisibility() throws {
        let subject = createSubject()
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.viewDidLoad
        )

        let dispatchExpectation = XCTestExpectation(description: "Update banner visibility middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.mainMenuProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (bannerVisibilityAction, bannerVisibilityActionCount) = try getActionInfo(for: .updateBannerVisibility)

        let bannerVisibilityActionType = try XCTUnwrap(
            bannerVisibilityAction.actionType as? MainMenuMiddlewareActionType
        )

        XCTAssertEqual(bannerVisibilityActionCount, 1)
        XCTAssertEqual(bannerVisibilityActionType, .updateBannerVisibility)
    }

    func test_viewDidLoadAction_requestTabInfo() throws {
        let subject = createSubject()
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.viewDidLoad
        )

        let dispatchExpectation = XCTestExpectation(description: "Request tab info middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.mainMenuProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (requestTabInfoAction, requestTabInfoActionCount) = try getActionInfo(for: .requestTabInfo)

        let requestTabInfoActionType = try XCTUnwrap(
            requestTabInfoAction.actionType as? MainMenuMiddlewareActionType
        )

        XCTAssertEqual(requestTabInfoActionCount, 1)
        XCTAssertEqual(requestTabInfoActionType, .requestTabInfo)
    }

    func test_viewDidLoadAction_requestTabInfoHeader() throws {
        let subject = createSubject()
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.viewDidLoad
        )

        let dispatchExpectation = XCTestExpectation(description: "Request tab info header middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.mainMenuProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (infoForHeaderAction, infoHeaderActionCount) = try getActionInfo(for: .requestTabInfoForSiteProtectionsHeader)

        let infoForHeaderActionType = try XCTUnwrap(
            infoForHeaderAction.actionType as? MainMenuMiddlewareActionType
        )

        XCTAssertEqual(infoHeaderActionCount, 1)
        XCTAssertEqual(infoForHeaderActionType, .requestTabInfoForSiteProtectionsHeader)
    }

    func test_updateMenuAppearanceAction_updateMenuAppearance() throws {
        let subject = createSubject()
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.updateMenuAppearance,
            isPhoneLandscape: false
        )

        let dispatchExpectation = XCTestExpectation(description: "Update menu appearance middleware action dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.mainMenuProvider(AppState(), action)

        wait(for: [dispatchExpectation], timeout: 1)

        let (updateMenuAppearanceAction, updateMenuAppearanceActionCount) = try getActionInfo(for: .updateMenuAppearance)

        let updateMenuAppearanceActionType = try XCTUnwrap(
            updateMenuAppearanceAction.actionType as? MainMenuMiddlewareActionType
        )

        XCTAssertEqual(updateMenuAppearanceActionCount, 1)
        XCTAssertEqual(updateMenuAppearanceActionType, .updateMenuAppearance)
        XCTAssertEqual(updateMenuAppearanceAction.isPhoneLandscape, false)
    }

    func test_menuDismissedAction_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.menuDismissed
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MenuDismissedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MenuDismissedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.menuDismissed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.isHomepage, false)
    }

    func test_tapZoomAction_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapZoom,
            telemetryInfo: TelemetryInfo(isHomepage: false)
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "zoom")
    }

    func test_tapAddToBookmarksAction_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapAddToBookmarks,
            telemetryInfo: TelemetryInfo(isHomepage: false)
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "bookmark_this_page")
    }

    func test_tapEditBookmarkAction_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapEditBookmark,
            telemetryInfo: TelemetryInfo(isHomepage: false)
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "edit_bookmark")
    }

    func test_tapAddToShortcutsAction_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapAddToShortcuts,
            telemetryInfo: TelemetryInfo(isHomepage: false)
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "add_to_shortcuts")
    }

    func test_tapRemoveFromShortcutsAction_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapRemoveFromShortcuts,
            telemetryInfo: TelemetryInfo(isHomepage: false)
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "remove_from_shortcuts")
    }

    func test_tapToggleNightModeActionON_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapToggleNightMode,
            telemetryInfo: TelemetryInfo(isHomepage: false, isActionOn: true)
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "night_mode_turn_on")
    }

    func test_tapToggleNightModeActionOFF_sendTelemetryData() throws {
        let action = MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapToggleNightMode,
            telemetryInfo: TelemetryInfo(isHomepage: false, isActionOn: false)
        )
        let subject = createSubject()

        subject.mainMenuProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.AppMenu.MainMenuOptionSelectedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.AppMenu.MainMenuOptionSelectedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.AppMenu.mainMenuOptionSelected)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.option, "night_mode_turn_off")
    }

    private func getNavigationDestinationAction(for destination: MainMenuNavigationDestination) -> MainMenuAction {
        return MainMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MainMenuActionType.tapNavigateToDestination,
            navigationDestination: MenuNavigationDestination(destination),
            telemetryInfo: TelemetryInfo(isHomepage: false)
        )
    }

    private func createSubject() -> MainMenuMiddleware {
        return MainMenuMiddleware(telemetry: MainMenuTelemetry(gleanWrapper: mockGleanWrapper))
    }

    private func getActionInfo(for actionType: MainMenuMiddlewareActionType)
    throws -> (MainMenuAction, Int) {
        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [MainMenuAction])

        let action = try XCTUnwrap(actionsCalled.first(where: {
            $0.actionType as? MainMenuMiddlewareActionType == actionType
        }))

        let actionCount = actionsCalled.filter {
            ($0.actionType as? MainMenuMiddlewareActionType) == actionType
        }.count

        return (action, actionCount)
    }

    // MARK: StoreTestUtility
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
