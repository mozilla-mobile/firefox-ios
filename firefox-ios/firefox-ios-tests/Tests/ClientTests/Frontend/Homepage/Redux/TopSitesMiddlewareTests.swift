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

    override func setUp() async throws {
        try await super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        mockGleanWrapper = MockGleanWrapper()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        mockGleanWrapper = nil
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    func test_homepageInitializeAction_returnsTopSitesSection() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let dispatchExpectation = XCTestExpectation(description: "All relevant top sites middleware actions are dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.topSitesProvider(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 1)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites])
        XCTAssertEqual(actionsCalled.last?.topSites?.count, 30)
    }

    func test_homepageSectionSeenAction_withUnifiedAds_sendTelemetryData() {
        let unifiedAdsTelemetry = MockUnifiedAdsCallbackTelemetry()
        let subject = createSubject(
            topSitesManager: mockTopSitesManager,
            unifiedAdsTelemetry: unifiedAdsTelemetry
        )
        let config = TopSiteConfiguration(
            site: Site.createSponsoredSite(fromUnifiedTile: MockSponsoredTileData.defaultSuccessData.first!)
        )
        let action = TopSitesAction(
            telemetryConfig: TopSitesTelemetryConfig(
                    isZeroSearch: false,
                    position: 0,
                    topSiteConfiguration: config
            ),
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.topSitesSeen
        )

        subject.topSitesProvider(AppState(), action)
        XCTAssertEqual(unifiedAdsTelemetry.sendImpressionTelemetryCalled, 1)
    }

    func test_fetchTopSitesAction_returnsTopSitesSection() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.topSitesUpdated
        )

        let dispatchExpectation = XCTestExpectation(description: "All relevant top sites middleware actions are dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.topSitesProvider(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 1)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites])
        XCTAssertEqual(actionsCalled.last?.topSites?.count, 30)
    }

    func test_fetchTopSitesAction_withMultipleCalles_returnsTopSitesSection() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.topSitesUpdated
        )

        let dispatchExpectation = XCTestExpectation(description: "All relevant top sites middleware actions are dispatched")

        dispatchExpectation.expectedFulfillmentCount = 3

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.topSitesProvider(appState, action)
        subject.topSitesProvider(appState, action)
        subject.topSitesProvider(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 3)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 3)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites, .retrievedUpdatedSites, .retrievedUpdatedSites])
        XCTAssertEqual(actionsCalled.last?.topSites?.count, 30)
    }

    func test_tappedOnHomepageTopSite_forSponsoredSites_withUnifiedAds_sendsTelemetry() throws {
        let unifiedAdsTelemetry = MockUnifiedAdsCallbackTelemetry()
        let subject = createSubject(
            topSitesManager: mockTopSitesManager,
            unifiedAdsTelemetry: unifiedAdsTelemetry
        )
        let config = TopSiteConfiguration(
            site: Site.createSponsoredSite(fromUnifiedTile: MockSponsoredTileData.defaultSuccessData.first!)
        )
        let action = TopSitesAction(
            telemetryConfig: TopSitesTelemetryConfig(isZeroSearch: true, position: 0, topSiteConfiguration: config),
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.tapOnHomepageTopSitesCell
        )

        subject.topSitesProvider(appState, action)

        try checkTopSitesPressedMetrics(label: "zero-search", position: "0", tileType: "sponsored")

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 2)
        XCTAssertEqual(mockGleanWrapper.incrementLabeledCounterCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(unifiedAdsTelemetry.sendClickTelemetryCalled, 1)
    }

    func test_tappedOnHomepageTopSite_withoutIsZeroSearch_forSuggestedSites_sendsCorrectTelemetry() throws {
        let unifiedAdsTelemetry = MockUnifiedAdsCallbackTelemetry()
        let subject = createSubject(
            topSitesManager: mockTopSitesManager,
            unifiedAdsTelemetry: unifiedAdsTelemetry
        )
        let config = TopSiteConfiguration(
            site: Site.createSuggestedSite(
                url: "www.mozilla.org",
                title: "Mozilla Site",
                trackingId: 0
            )
        )
        let action = TopSitesAction(
            telemetryConfig: TopSitesTelemetryConfig(isZeroSearch: false, position: 1, topSiteConfiguration: config),
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.tapOnHomepageTopSitesCell
        )

        subject.topSitesProvider(appState, action)

        try checkTopSitesPressedMetrics(label: "origin-other", position: "1", tileType: "suggested")

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 2)
        XCTAssertEqual(mockGleanWrapper.incrementLabeledCounterCalled, 1)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(unifiedAdsTelemetry.sendImpressionTelemetryCalled, 0)
    }

    func test_tappedOnHomepageTopSite_withoutConfig_doesNotSendTelemetry() throws {
        let unifiedAdsTelemetry = MockUnifiedAdsCallbackTelemetry()
        let subject = createSubject(
            topSitesManager: mockTopSitesManager,
            unifiedAdsTelemetry: unifiedAdsTelemetry
        )
        let action = TopSitesAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.tapOnHomepageTopSitesCell
        )

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordLabelCalled, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssertEqual(unifiedAdsTelemetry.sendImpressionTelemetryCalled, 0)
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

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
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
        let unpinTopSiteExpectation = XCTestExpectation(
            description: "Unpin top sites method is called from top site manager"
        )
        mockTopSitesManager.unpinTopSiteCalled = {
            unpinTopSiteExpectation.fulfill()
        }

        subject.topSitesProvider(appState, action)

        try checkContextMenuMetricsCalled(withExtra: "unpin")

        wait(for: [unpinTopSiteExpectation], timeout: 1)
    }

    func test_tappedOnUnpinTopSite_withoutSite_doesNotCallUnpinTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(windowUUID: .XCTestDefaultUUID, actionType: ContextMenuActionType.tappedOnUnpinTopSite)

        let unpinTopSiteExpectation = XCTestExpectation(
            description: "Unpin top sites method is called from top site manager"
        )
        unpinTopSiteExpectation.isInverted = true
        mockTopSitesManager.unpinTopSiteCalled = {
            unpinTopSiteExpectation.fulfill()
        }

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        wait(for: [unpinTopSiteExpectation], timeout: 1)
    }

    func test_tappedOnRemoveTopSite_withSite_callsRemoveTopSite() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            site: site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnRemoveTopSite
        )

        let removeTopSiteExpectation = XCTestExpectation(
            description: "Remove top sites method is called from top site manager"
        )
        mockTopSitesManager.removeTopSiteCalled = {
            removeTopSiteExpectation.fulfill()
        }

        subject.topSitesProvider(appState, action)

        try checkContextMenuMetricsCalled(withExtra: "remove")

        wait(for: [removeTopSiteExpectation], timeout: 1)
    }

    func test_tappedOnRemoveTopSite_withoutSite_doesNotCallRemoveTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(windowUUID: .XCTestDefaultUUID, actionType: ContextMenuActionType.tappedOnRemoveTopSite)

        let removeTopSiteExpectation = XCTestExpectation(
            description: "Remove top sites method is called from top site manager"
        )
        removeTopSiteExpectation.isInverted = true

        mockTopSitesManager.removeTopSiteCalled = {
            removeTopSiteExpectation.fulfill()
        }

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        wait(for: [removeTopSiteExpectation], timeout: 1)
    }

    func test_tappedOnOpenNewPrivateTabAction_sendTelemetryData() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)

        let topSiteItem: HomepageItem = .topSite(
            TopSiteConfiguration(
                site: Site.createBasicSite(url: "www.example.com/1234", title: "Site 0")
            ), nil
        )
        guard case let .topSite(state, nil) = topSiteItem else { return }
        let action = ContextMenuAction(
            menuType: MenuType(homepageItem: topSiteItem),
            site: state.site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnOpenNewPrivateTab
        )

        subject.topSitesProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
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
    private func createSubject(
        topSitesManager: MockTopSitesManager,
        unifiedAdsTelemetry: UnifiedAdsCallbackTelemetry? = nil
    ) -> TopSitesMiddleware {
        return TopSitesMiddleware(
            topSitesManager: topSitesManager,
            homepageTelemetry: HomepageTelemetry(gleanWrapper: mockGleanWrapper),
            bookmarksTelemetry: BookmarksTelemetry(gleanWrapper: mockGleanWrapper),
            unifiedAdsTelemetry: unifiedAdsTelemetry ??  MockUnifiedAdsCallbackTelemetry()
        )
    }

    private func checkContextMenuMetricsCalled(withExtra extra: String) throws {
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ContextualMenuExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.TopSites.ContextualMenuExtra
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
            mockGleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>
        )

        let expectedFirstMetricType = type(of: GleanMetrics.TopSites.pressedTileOrigin)
        let firstResultMetricType = type(of: firstSavedMetric)
        let debugMessage = TelemetryDebugMessage(
            expectedMetric: expectedFirstMetricType,
            resultMetric: firstResultMetricType
        )

        let secondSavedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents[safe: 1] as? EventMetricType<GleanMetrics.TopSites.TilePressedExtra>
        )
        let secondSavedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.TopSites.TilePressedExtra
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
