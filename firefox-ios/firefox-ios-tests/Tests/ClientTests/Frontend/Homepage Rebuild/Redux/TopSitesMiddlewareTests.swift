// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage
import XCTest

@testable import Client

final class TopSitesMiddlewareTests: XCTestCase, StoreTestUtility {
    let mockTopSitesManager = MockTopSitesManager()
    var mockStore: MockStoreForMiddleware<AppState>!
    var appState: AppState!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
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

    func test_tappedOnPinTopSite_withSite_callsPinTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            site: site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnPinTopSite
        )

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockTopSitesManager.pinTopSiteCalledCount, 1)
    }

    func test_tappedOnPinTopSite_withoutSite_doesNotCallPinTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = ContextMenuAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnPinTopSite
        )

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockTopSitesManager.pinTopSiteCalledCount, 0)
    }

    func test_tappedOnUnpinTopSite_withSite_callsUnpinTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            site: site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnUnpinTopSite
        )

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockTopSitesManager.unpinTopSiteCalledCount, 1)
    }

    func test_tappedOnUnpinTopSite_withoutSite_doesNotCallUnpinTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(windowUUID: .XCTestDefaultUUID, actionType: ContextMenuActionType.tappedOnUnpinTopSite)

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockTopSitesManager.unpinTopSiteCalledCount, 0)
    }

    func test_tappedOnRemoveTopSite_withSite_callsRemoveTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let site = Site.createBasicSite(url: "www.example.com", title: "Pinned Top Site")
        let action = ContextMenuAction(
            site: site,
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnRemoveTopSite
        )

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockTopSitesManager.removeTopSiteCalledCount, 1)
    }

    func test_tappedOnRemoveTopSite_withoutSite_doesNotCallRemoveTopSite() {
        let subject = createSubject(topSitesManager: mockTopSitesManager)
        let action = TopSitesAction(windowUUID: .XCTestDefaultUUID, actionType: ContextMenuActionType.tappedOnRemoveTopSite)

        subject.topSitesProvider(appState, action)

        XCTAssertEqual(mockTopSitesManager.removeTopSiteCalledCount, 0)
    }

    // MARK: - Helpers
    private func createSubject(topSitesManager: MockTopSitesManager) -> TopSitesMiddleware {
        return TopSitesMiddleware(topSitesManager: topSitesManager)
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
