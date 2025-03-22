// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Glean
import Redux
import Storage
import XCTest

@testable import Client

final class TopSitesMiddlewareTests: XCTestCase, StoreTestUtility {
    let mockTopSitesManager = MockTopSitesManager()
    var mockGleanWrapper: MockGleanWrapper!
    var mockStore: MockStoreForMiddleware<AppState>!
    var appState: AppState!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        mockGleanWrapper = nil
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func test_homepageInitializeAction_returnsTopSitesSection() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let expectation = XCTestExpectation(description: "All relevant top sites middleware actions are dispatched")
        expectation.expectedFulfillmentCount = 3

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.topSitesProvider(appState, action)

        wait(for: [expectation])

        XCTAssertEqual(mockTopSitesManager.getOtherSitesCalledCount, 1)
        XCTAssertEqual(mockTopSitesManager.fetchSponsoredSitesCalledCount, 1)
        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 3)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 3)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites, .retrievedUpdatedSites, .retrievedUpdatedSites])
        XCTAssertEqual(actionsCalled.last?.topSites?.count, 30)
    }

    func test_fetchTopSitesAction_returnsTopSitesSection() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.fetchTopSites
        )

        let expectation = XCTestExpectation(description: "All top sites middleware actions are dispatched")
        expectation.expectedFulfillmentCount = 3

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.topSitesProvider(appState, action)

        wait(for: [expectation])

        XCTAssertEqual(mockTopSitesManager.getOtherSitesCalledCount, 1)
        XCTAssertEqual(mockTopSitesManager.fetchSponsoredSitesCalledCount, 1)
        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 3)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 3)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites, .retrievedUpdatedSites, .retrievedUpdatedSites])
        XCTAssertEqual(actionsCalled.last?.topSites?.count, 30)
    }

    func test_tappedOnHomepageTopSite_sendsTelemetry() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(
            telemetryConfig: TopSitesTelemetryConfig(
                isZeroSearch: true,
                position: 0,
                tileType: "sponsored",
                url: "www.mozilla.org"
            ),
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.tapOnHomepageTopSitesCell
        )

        subject.topSitesProvider(appState, action)

        try checkTopSitesPressedMetrics(label: "zero-search", position: "0", tileType: "sponsored")

        XCTAssertEqual(mockGleanWrapper.savedEvents?.count, 2)
        XCTAssertEqual(mockGleanWrapper.recordLabelCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
    }

    func test_tappedOnHomepageTopSite_withoutIsZeroSearch_sendsTelemetry() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(
            telemetryConfig: TopSitesTelemetryConfig(
                isZeroSearch: false,
                position: 1,
                tileType: "suggested",
                url: "www.mozilla.org"
            ),
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.tapOnHomepageTopSitesCell
        )

        subject.topSitesProvider(appState, action)

        try checkTopSitesPressedMetrics(label: "origin-other", position: "1", tileType: "suggested")

        XCTAssertEqual(mockGleanWrapper.savedEvents?.count, 2)
        XCTAssertEqual(mockGleanWrapper.recordLabelCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
    }

    func test_tappedOnHomepageTopSite_withoutConfig_doesNotSendTelemetry() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.tapOnHomepageTopSitesCell
        )

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents?.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordLabelCalled, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
    }

    // MARK: Context Menu

    func test_tappedOnPinTopSite_withSite_callsPinTopSite() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            site: site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnPinTopSite
        )

        subject.topSitesProvider(appState, action)

        try checkContextMenuMetricsCalled(withExtra: "pin")

        XCTAssertEqual(mockTopSitesManager.pinTopSiteCalledCount, 1)
    }

    func test_tappedOnPinTopSite_withoutSite_doesNotCallPinTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = ContextMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnPinTopSite
        )

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents?.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssertEqual(mockTopSitesManager.pinTopSiteCalledCount, 0)
    }

    func test_tappedOnUnpinTopSite_withSite_callsUnpinTopSite() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            site: site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnUnpinTopSite
        )

        subject.topSitesProvider(appState, action)

        try checkContextMenuMetricsCalled(withExtra: "unpin")

        XCTAssertEqual(mockTopSitesManager.unpinTopSiteCalledCount, 1)
    }

    func test_tappedOnUnpinTopSite_withoutSite_doesNotCallUnpinTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(windowUUID: .XCTestDefaultUUID, actionType: ContextMenuActionType.tappedOnUnpinTopSite)

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents?.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssertEqual(mockTopSitesManager.unpinTopSiteCalledCount, 0)
    }

    func test_tappedOnRemoveTopSite_withSite_callsRemoveTopSite() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            site: site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnRemoveTopSite
        )

        subject.topSitesProvider(appState, action)

        try checkContextMenuMetricsCalled(withExtra: "remove")

        XCTAssertEqual(mockTopSitesManager.removeTopSiteCalledCount, 1)
    }

    func test_tappedOnRemoveTopSite_withoutSite_doesNotCallRemoveTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(windowUUID: .XCTestDefaultUUID, actionType: ContextMenuActionType.tappedOnRemoveTopSite)

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents?.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssertEqual(mockTopSitesManager.removeTopSiteCalledCount, 0)
    }

    func test_tappedOnOpenNewPrivateTabAction_sendTelemetryData() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = ContextMenuAction(
            section: .topSites(4),
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnOpenNewPrivateTab
        )
        subject.topSitesProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents?[0] as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.TopSites.openInPrivateTab)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_tappedOnSettingsAction_sendTelemetryData() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = ContextMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnSettingsAction
        )
        subject.topSitesProvider(AppState(), action)

        try checkContextMenuMetricsCalled(withExtra: "settings")
    }

    func test_tappedOnSponsoredAction_sendTelemetryData() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = ContextMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnSponsoredAction
        )
        subject.topSitesProvider(AppState(), action)

        try checkContextMenuMetricsCalled(withExtra: "sponsoredSupport")
    }

    // MARK: - Helpers
    private func createSubject(topSitesManager: MockTopSitesManager) -> TopSitesMiddleware {
        return TopSitesMiddleware(
            topSitesManager: topSitesManager,
            homepageTelemetry: HomepageTelemetry(gleanWrapper: mockGleanWrapper),
            bookmarksTelemetry: BookmarksTelemetry(gleanWrapper: mockGleanWrapper)
        )
    }

    private func checkContextMenuMetricsCalled(withExtra extra: String) throws {
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents?[0] as? EventMetricType<GleanMetrics.TopSites.ContextualMenuExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras as? GleanMetrics.TopSites.ContextualMenuExtra
        )
        let expectedMetricType = type(of: GleanMetrics.TopSites.contextualMenu)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
        XCTAssertEqual(savedExtras.type, extra)
    }

    private func checkTopSitesPressedMetrics(label: String, position: String, tileType: String) throws {
        let firstSavedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents?[0] as? LabeledMetricType<CounterMetricType>
        )

        let expectedFirstMetricType = type(of: GleanMetrics.TopSites.pressedTileOrigin)
        let firstResultMetricType = type(of: firstSavedMetric)
        let debugMessage = TelemetryDebugMessage(
            expectedMetric: expectedFirstMetricType,
            resultMetric: firstResultMetricType
        )

        let secondSavedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents?[1] as? EventMetricType<GleanMetrics.TopSites.TilePressedExtra>
        )
        let secondSavedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras as? GleanMetrics.TopSites.TilePressedExtra
        )
        let expectedSecondMetricType = type(of: GleanMetrics.TopSites.tilePressed)
        let secondResultMetricType = type(of: secondSavedMetric)
        let secondDebugMessage = TelemetryDebugMessage(
            expectedMetric: expectedSecondMetricType,
            resultMetric: secondResultMetricType
        )

        XCTAssert(firstResultMetricType == expectedFirstMetricType, debugMessage.text)
        XCTAssert(secondResultMetricType == expectedSecondMetricType, secondDebugMessage.text)

        XCTAssertEqual(mockGleanWrapper.savedLabel as? String, label)
        XCTAssertEqual(secondSavedExtras.position, position)
        XCTAssertEqual(secondSavedExtras.tileType, tileType)
    }

    // MARK: StoreTestUtility
    func setupAppState() -> Client.AppState {
        appState = AppState()
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
