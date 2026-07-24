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

        subject.topSitesProvider.legacyMiddleware(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 1)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites])
        XCTAssertEqual(actionsCalled.last?.topSites?.count, 30)
    }

    func test_homepageInitializeAction_whenAddShortcutTileFlagEnabled_dispatchesAddShortcutTileState() throws {
        let featureFlags = MockNimbusFeatureFlags()
        featureFlags.enabledFlags.insert(.homepageAddShortcutTile)
        let subject = createSubject(topSitesManager: mockTopSitesManager, featureFlagsProvider: featureFlags)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )

        let dispatchExpectation = XCTestExpectation(description: "Top sites state update is dispatched")
        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.topSitesProvider.legacyMiddleware(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        XCTAssertTrue(actionsCalled.last?.shouldShowAddShortcutTile == true)
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

        subject.topSitesProvider.legacyMiddleware(AppState(), action)
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

        subject.topSitesProvider.legacyMiddleware(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 1)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites])
        XCTAssertEqual(actionsCalled.last?.topSites?.count, 30)
    }

    func test_didBecomeActiveAction_returnsTopSitesSection() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.didBecomeActive
        )

        let dispatchExpectation = XCTestExpectation(description: "All relevant top sites middleware actions are dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.topSitesProvider.legacyMiddleware(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 1)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites])
        XCTAssertEqual(actionsCalled.last?.topSites?.count, 30)
    }

    func test_fetchTopSitesAction_withMultipleCalls_coalescesTopSitesRefresh() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.topSitesUpdated
        )

        let dispatchExpectation = XCTestExpectation(description: "All relevant top sites middleware actions are dispatched")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.topSitesProvider.legacyMiddleware(appState, action)
        subject.topSitesProvider.legacyMiddleware(appState, action)
        subject.topSitesProvider.legacyMiddleware(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 1)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites])
        XCTAssertEqual(actionsCalled.last?.topSites?.count, 30)
    }

    func test_shortcutsLibraryInitializeAction_withMultipleCalls_doesNotCoalesceTopSitesRefresh() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = ShortcutsLibraryAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.initialize
        )

        let dispatchExpectation = XCTestExpectation(description: "Top sites middleware dispatches each shortcut update")
        dispatchExpectation.expectedFulfillmentCount = 3

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.topSitesProvider.legacyMiddleware(appState, action)
        subject.topSitesProvider.legacyMiddleware(appState, action)
        subject.topSitesProvider.legacyMiddleware(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        XCTAssertEqual(mockTopSitesManager.recalculateTopSitesCalledCount, 3)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let actionsType = try XCTUnwrap(actionsCalled.compactMap { $0.actionType } as? [TopSitesMiddlewareActionType])

        XCTAssertEqual(mockStore.dispatchedActions.count, 3)
        XCTAssertEqual(actionsType, [.retrievedUpdatedSites, .retrievedUpdatedSites, .retrievedUpdatedSites])
    }

    func test_homepageInitializeAction_withoutSponsoredSites_dispatchesOtherSites() throws {
        let topSitesManager = FallbackTopSitesManager()
        let subject = createSubject(topSitesManager: topSitesManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageActionType.initialize
        )
        let dispatchExpectation = XCTestExpectation(description: "Top sites middleware dispatches fallback sites")

        mockStore.dispatchCalled = {
            dispatchExpectation.fulfill()
        }

        subject.topSitesProvider.legacyMiddleware(appState, action)

        wait(for: [dispatchExpectation], timeout: 1)

        let actionsCalled = try XCTUnwrap(mockStore.dispatchedActions as? [TopSitesAction])
        let topSites = try XCTUnwrap(actionsCalled.last?.topSites)

        XCTAssertEqual(topSites.count, 1)
        XCTAssertEqual(topSites.first?.title, "Fallback Site")
        XCTAssertEqual(topSites.first?.isSponsored, false)
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

        subject.topSitesProvider.legacyMiddleware(appState, action)

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

        subject.topSitesProvider.legacyMiddleware(appState, action)

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

        subject.topSitesProvider.legacyMiddleware(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssertEqual(unifiedAdsTelemetry.sendImpressionTelemetryCalled, 0)
    }

    // MARK: Context Menu

    func test_tappedOnPinTopSite_withSite_sendsPinTelemetryEvents() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            site: site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnPinTopSite
        )

        subject.topSitesProvider.legacyMiddleware(appState, action)

        let contextMenuMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ContextualMenuExtra>
        )
        let contextMenuExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.TopSites.ContextualMenuExtra
        )
        let pinnedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.last as? EventMetricType<GleanMetrics.TopSites.ShortcutPinnedExtra>
        )
        let pinnedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.last as? GleanMetrics.TopSites.ShortcutPinnedExtra
        )
        let contextMenuEvent = GleanMetrics.TopSites.contextualMenu
        let pinnedEvent = GleanMetrics.TopSites.shortcutPinned

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 2)
        XCTAssert(contextMenuMetric === contextMenuEvent,
                  "Received \(contextMenuMetric) instead of \(contextMenuEvent)")
        XCTAssertEqual(contextMenuExtras.type, "pin")
        XCTAssert(pinnedMetric === pinnedEvent, "Received \(pinnedMetric) instead of \(pinnedEvent)")
        XCTAssertEqual(pinnedExtras.source, "context_menu")

        XCTAssertEqual(mockTopSitesManager.pinTopSiteCalledCount, 1)
    }

    func test_tappedOnPinTopSite_withoutSite_doesNotCallPinTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = ContextMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnPinTopSite
        )

        subject.topSitesProvider.legacyMiddleware(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        XCTAssertEqual(mockTopSitesManager.pinTopSiteCalledCount, 0)
    }

    func test_tappedOnPinTopSite_fromShortcutContextMenu_sendsContextMenuSource() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            menuType: .shortcut,
            site: site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnPinTopSite
        )

        subject.topSitesProvider.legacyMiddleware(appState, action)

        let pinnedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.last as? GleanMetrics.TopSites.ShortcutPinnedExtra
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(pinnedExtras.source, "context_menu")
    }

    func test_tappedOnUnpinTopSite_withSite_sendsUnpinTelemetryEvents() throws {
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

        subject.topSitesProvider.legacyMiddleware(appState, action)

        let contextMenuMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ContextualMenuExtra>
        )
        let contextMenuExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.TopSites.ContextualMenuExtra
        )
        let unpinnedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.last as? EventMetricType<GleanMetrics.TopSites.ShortcutUnpinnedExtra>
        )
        let unpinnedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.last as? GleanMetrics.TopSites.ShortcutUnpinnedExtra
        )
        let contextMenuEvent = GleanMetrics.TopSites.contextualMenu
        let unpinnedEvent = GleanMetrics.TopSites.shortcutUnpinned

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 2)
        XCTAssert(contextMenuMetric === contextMenuEvent,
                  "Received \(contextMenuMetric) instead of \(contextMenuEvent)")
        XCTAssertEqual(contextMenuExtras.type, "unpin")
        XCTAssert(unpinnedMetric === unpinnedEvent, "Received \(unpinnedMetric) instead of \(unpinnedEvent)")
        XCTAssertEqual(unpinnedExtras.source, "context_menu")

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

        subject.topSitesProvider.legacyMiddleware(appState, action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
        wait(for: [unpinTopSiteExpectation], timeout: 1)
    }

    func test_tappedOnUnpinTopSite_fromShortcutContextMenu_sendsContextMenuSource() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            menuType: .shortcut,
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

        subject.topSitesProvider.legacyMiddleware(appState, action)

        let unpinnedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.last as? GleanMetrics.TopSites.ShortcutUnpinnedExtra
        )

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 2)
        XCTAssertEqual(unpinnedExtras.source, "context_menu")
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

        subject.topSitesProvider.legacyMiddleware(appState, action)

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

        subject.topSitesProvider.legacyMiddleware(appState, action)

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

        subject.topSitesProvider.legacyMiddleware(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let event = GleanMetrics.TopSites.openInPrivateTab

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
    }

    func test_tappedOnSettingsAction_sendTelemetryData() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = ContextMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnSettingsAction
        )
        subject.topSitesProvider.legacyMiddleware(AppState(), action)

        try checkContextMenuMetricsCalled(withExtra: "settings")
    }

    func test_tappedOnSponsoredAction_sendTelemetryData() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = ContextMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnSponsoredAction
        )
        subject.topSitesProvider.legacyMiddleware(AppState(), action)

        try checkContextMenuMetricsCalled(withExtra: "sponsoredSupport")
    }

    func test_shortcutPinnedAction_sendTelemetryData() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let homeScreenAction = TopSitesAction(
            shortcutPinnedSource: .homescreenButton,
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.shortcutPinned
        )
        let appMenuAction = TopSitesAction(
            shortcutPinnedSource: .appMenu,
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.shortcutPinned
        )
        let contextMenuAction = TopSitesAction(
            shortcutPinnedSource: .contextMenu,
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.shortcutPinned
        )

        subject.topSitesProvider.legacyMiddleware(AppState(), homeScreenAction)
        subject.topSitesProvider.legacyMiddleware(AppState(), appMenuAction)
        subject.topSitesProvider.legacyMiddleware(AppState(), contextMenuAction)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ShortcutPinnedExtra>
        )
        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras as? [GleanMetrics.TopSites.ShortcutPinnedExtra])
        let event = GleanMetrics.TopSites.shortcutPinned

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 3)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
        XCTAssertEqual(savedExtras.map(\.source), ["homescreen_button", "app_menu", "context_menu"])
    }

    func test_shortcutUnpinnedAction_sendTelemetryData() throws {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let contextMenuAction = TopSitesAction(
            shortcutUnpinnedSource: .contextMenu,
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.shortcutUnpinned
        )
        let appMenuAction = TopSitesAction(
            shortcutUnpinnedSource: .appMenu,
            windowUUID: .XCTestDefaultUUID,
            actionType: TopSitesActionType.shortcutUnpinned
        )

        subject.topSitesProvider.legacyMiddleware(AppState(), contextMenuAction)
        subject.topSitesProvider.legacyMiddleware(AppState(), appMenuAction)

        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ShortcutUnpinnedExtra>
        )
        let savedExtras = try XCTUnwrap(mockGleanWrapper.savedExtras as? [GleanMetrics.TopSites.ShortcutUnpinnedExtra])
        let event = GleanMetrics.TopSites.shortcutUnpinned

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 2)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
        XCTAssertEqual(savedExtras.map(\.source), ["context_menu", "app_menu"])
    }

    // MARK: - Helpers
    private func createSubject(
        topSitesManager: TopSitesManagerInterface,
        unifiedAdsTelemetry: UnifiedAdsCallbackTelemetry? = nil,
        featureFlagsProvider: FeatureFlagProviding = MockNimbusFeatureFlags()
    ) -> TopSitesMiddleware {
        return TopSitesMiddleware(
            topSitesManager: topSitesManager,
            homepageTelemetry: HomepageTelemetry(gleanWrapper: mockGleanWrapper),
            bookmarksTelemetry: BookmarksTelemetry(gleanWrapper: mockGleanWrapper),
            unifiedAdsTelemetry: unifiedAdsTelemetry ??  MockUnifiedAdsCallbackTelemetry(),
            featureFlagsProvider: featureFlagsProvider
        )
    }

    private func checkContextMenuMetricsCalled(withExtra extra: String) throws {
        let savedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? EventMetricType<GleanMetrics.TopSites.ContextualMenuExtra>
        )
        let savedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.TopSites.ContextualMenuExtra
        )
        let event = GleanMetrics.TopSites.contextualMenu

        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 1)
        XCTAssert(savedMetric === event, "Received \(savedMetric) instead of \(event)")
        XCTAssertEqual(savedExtras.type, extra)
    }

    private func checkTopSitesPressedMetrics(label: String, position: String, tileType: String) throws {
        let firstMetric = GleanMetrics.TopSites.pressedTileOrigin
        let secondMetric = GleanMetrics.TopSites.tilePressed
        let firstSavedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>
        )
        let secondSavedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents[safe: 1] as? EventMetricType<GleanMetrics.TopSites.TilePressedExtra>
        )
        let secondSavedExtras = try XCTUnwrap(
            mockGleanWrapper.savedExtras.first as? GleanMetrics.TopSites.TilePressedExtra
        )

        XCTAssert(firstSavedMetric === firstMetric, "Received \(firstSavedMetric) instead of \(firstMetric)")
        XCTAssert(secondSavedMetric === secondMetric, "Received \(secondSavedMetric) instead of \(secondMetric)")

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

private final class FallbackTopSitesManager: TopSitesManagerInterface, @unchecked Sendable {
    func getOtherSites() async -> [TopSiteConfiguration] {
        return [
            TopSiteConfiguration(
                site: Site.createBasicSite(url: "www.example.com", title: "Fallback Site")
            )
        ]
    }

    func fetchSponsoredSites() async -> [Site] {
        return []
    }

    @MainActor
    func recalculateTopSites(otherSites: [TopSiteConfiguration], sponsoredSites: [Site]) -> [TopSiteConfiguration] {
        return otherSites
    }

    func removeTopSite(_ site: Site) async {}

    func pinTopSite(_ site: Site) {}

    func unpinTopSite(_ site: Site) async {}
}
