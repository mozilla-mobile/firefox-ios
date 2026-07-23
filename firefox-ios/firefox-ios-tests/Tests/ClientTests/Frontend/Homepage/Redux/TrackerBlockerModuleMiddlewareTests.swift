// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class TrackerBlockerModuleMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    func test_initializeAction_dispatchesLifetimeBlockedCount() throws {
        let subject = createSubject(lifetimeTotal: 4567)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        let expectation = XCTestExpectation(description: "updateBlockedCount dispatched")

        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.trackerBlockerModuleProvider.legacyMiddleware(AppState(), action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? TrackerBlockerModuleAction)
        let actionType = try XCTUnwrap(dispatched.actionType as? TrackerBlockerModuleMiddlewareActionType)
        XCTAssertEqual(actionType, TrackerBlockerModuleMiddlewareActionType.updateBlockedCount)
        XCTAssertEqual(dispatched.blockedTrackerCount, 4567)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
    }

    func test_viewDidAppearAction_dispatchesLifetimeBlockedCount() throws {
        let subject = createSubject(lifetimeTotal: 12)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.viewDidAppear)
        let expectation = XCTestExpectation(description: "updateBlockedCount dispatched")

        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.trackerBlockerModuleProvider.legacyMiddleware(AppState(), action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? TrackerBlockerModuleAction)
        XCTAssertEqual(dispatched.blockedTrackerCount, 12)
    }

    func test_didBecomeActiveAction_dispatchesLifetimeBlockedCount() throws {
        let subject = createSubject(lifetimeTotal: 99)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.didBecomeActive
        )
        let expectation = XCTestExpectation(description: "updateBlockedCount dispatched")

        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.trackerBlockerModuleProvider.legacyMiddleware(AppState(), action)

        wait(for: [expectation])

        let dispatched = try XCTUnwrap(mockStore.dispatchedActions.first as? TrackerBlockerModuleAction)
        XCTAssertEqual(dispatched.blockedTrackerCount, 99)
    }

    func test_unrelatedAction_doesNotDispatch() throws {
        let subject = createSubject(lifetimeTotal: 5)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.viewWillDisappear)
        let expectation = XCTestExpectation(description: "No action dispatched")
        expectation.isInverted = true

        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.trackerBlockerModuleProvider.legacyMiddleware(AppState(), action)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
    }

    // MARK: - Helpers

    private func createSubject(lifetimeTotal: Int) -> TrackerBlockerModuleMiddleware {
        let store = MockTrackerBlockStatsStore()
        store.lifetimeTotalToReturn = lifetimeTotal
        return TrackerBlockerModuleMiddleware(statsStore: store)
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .homepage(
                        HomepageState(windowUUID: .XCTestDefaultUUID)
                    ),
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}

private final class MockTrackerBlockStatsStore: TrackerBlockStatsStore {
    var lifetimeTotalToReturn = 0

    func record(category: BlocklistCategory, count: Int, date: Date) {}
    func lifetimeTotal() -> Int { return lifetimeTotalToReturn }
    func lifetimeByCategory() -> [BlocklistCategory: Int] { return [:] }
    func weeklyTotal(for date: Date) -> Int { return 0 }
    func weeklyByCategory(for date: Date) -> [BlocklistCategory: Int] { return [:] }
    func reset() {}
}
