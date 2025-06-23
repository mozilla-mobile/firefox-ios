// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class HomepageMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockGleanWrapper: MockGleanWrapper!
    var mockStore: MockStoreForMiddleware<AppState>!
    var mockNotificationCenter: MockNotificationCenter!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
        mockNotificationCenter = MockNotificationCenter()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        mockGleanWrapper = nil
        mockNotificationCenter = nil
        resetStore()
        super.tearDown()
    }

    func test_init_setsUpNotifications() {
        _ = createSubject()

        XCTAssertEqual(mockNotificationCenter?.addObserverCallCount, 8)
        XCTAssertEqual(mockNotificationCenter?.observers, [UIApplication.didBecomeActiveNotification,
                                                           .FirefoxAccountChanged,
                                                           .PrivateDataClearedHistory,
                                                           .ProfileDidFinishSyncing,
                                                           .TopSitesUpdated,
                                                           .DefaultSearchEngineUpdated,
                                                           .BookmarksUpdated,
                                                           .RustPlacesOpened
        ])
    }

    func test_viewWillAppearAction_sendsTelemetryData() throws {
        let subject = createSubject()
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.viewWillAppear
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.Homepage.viewed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_shouldShowImpressionTriggeredAction_sendsTelemetryData() throws {
        let subject = createSubject()
        let action = GeneralBrowserAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.Homepage.viewed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_tapOnCustomizeHomepageAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.settings(.homePage)),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnCustomizeHomepageButton
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "customize_homepage_button")
        XCTAssertEqual(savedExtras.section, "customize_homepage")
    }

    func test_tapOnBookmarksShowMoreButtonAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.link),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnBookmarksShowMoreButton
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "bookmarks_show_all_button")
        XCTAssertEqual(savedExtras.section, "bookmarks")
    }

    func test_tapOnJumpBackInShowAllButtonAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.tabTray(.tabs)),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnJumpBackInShowAllButton
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "jump_back_in_show_all_button")
        XCTAssertEqual(savedExtras.section, "jump_back_in")
    }

    func test_tapOnJumpBackInSyncedShowAllButtonAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = NavigationBrowserAction(
            navigationDestination: NavigationDestination(.tabTray(.syncedTabs)),
            windowUUID: .XCTestDefaultUUID,
            actionType: NavigationBrowserActionType.tapOnJumpBackInShowAllButton
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "synced_show_all_button")
        XCTAssertEqual(savedExtras.section, "jump_back_in")
    }

    func test_didSelectItemAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = HomepageAction(
            telemetryExtras: HomepageTelemetryExtras(itemType: .topSite, topSitesTelemetryConfig: nil),
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.didSelectItem
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.Homepage.ItemTappedExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.Homepage.ItemTappedExtra
        )
        let expectedMetricType = type(of: GleanMetrics.Homepage.itemTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, "top_site")
        XCTAssertEqual(savedExtras.section, "top_sites")
    }

    func test_sectionSeenAction_sendTelemetryData() throws {
        let subject = createSubject()
        let action = HomepageAction(
            telemetryExtras: HomepageTelemetryExtras(itemType: .topSite, topSitesTelemetryConfig: nil),
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.sectionSeen
        )

        subject.homepageProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>)
        let expectedMetricType = type(of: GleanMetrics.Homepage.sectionViewed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordLabelCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(mockGleanWrapper?.savedLabel as? String, "top_sites")
    }

    // MARK: - Helpers
    private func createSubject() -> HomepageMiddleware {
        return HomepageMiddleware(
            homepageTelemetry: HomepageTelemetry(
                gleanWrapper: mockGleanWrapper
            ),
            notificationCenter: mockNotificationCenter
        )
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .homepage(
                        HomepageState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    ),
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
