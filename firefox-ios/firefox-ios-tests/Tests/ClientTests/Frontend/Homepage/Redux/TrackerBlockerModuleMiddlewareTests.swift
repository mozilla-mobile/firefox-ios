// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class TrackerBlockerModuleMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!
    var gleanWrapper: MockGleanWrapper!
    private var statsStore: MockTrackerBlockStatsStore!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        gleanWrapper = MockGleanWrapper()
        statsStore = MockTrackerBlockStatsStore()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        gleanWrapper = nil
        statsStore = nil
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

    // MARK: - Lifetime threshold telemetry

    func test_lifetimeBelowFourFigures_doesNotRecordThresholdTelemetry() {
        let subject = createSubject(lifetimeTotal: 40)

        dispatchInitialize(on: subject)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 0)
        XCTAssertEqual(statsStore.highestReportedFiguresToReturn, 0)
    }

    func test_lifetimeCrossesFourFigures_recordsThresholdOnce() throws {
        let subject = createSubject(lifetimeTotal: 1200)

        dispatchInitialize(on: subject)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(try recordedFigures(), [4])
        XCTAssertEqual(statsStore.highestReportedFiguresToReturn, 4)
    }

    func test_lifetimeAlreadyReported_doesNotReRecordThreshold() {
        statsStore.highestReportedFiguresToReturn = 4
        let subject = createSubject(lifetimeTotal: 1300)

        dispatchInitialize(on: subject)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 0)
        XCTAssertEqual(statsStore.highestReportedFiguresToReturn, 4)
    }

    func test_lifetimeCrossesNextBoundary_recordsOnlyNewBoundary() throws {
        statsStore.highestReportedFiguresToReturn = 4
        let subject = createSubject(lifetimeTotal: 12_000)

        dispatchInitialize(on: subject)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1)
        XCTAssertEqual(try recordedFigures(), [5])
        XCTAssertEqual(statsStore.highestReportedFiguresToReturn, 5)
    }

    func test_lifetimeJumpsMultipleBoundaries_recordsEachOnce() throws {
        let subject = createSubject(lifetimeTotal: 120_000)

        dispatchInitialize(on: subject)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 3)
        XCTAssertEqual(try recordedFigures(), [4, 5, 6])
        XCTAssertEqual(statsStore.highestReportedFiguresToReturn, 6)
    }

    func test_lifetimeAboveEightFigures_capsAtEightFigures() throws {
        let subject = createSubject(lifetimeTotal: 1_500_000_000)

        dispatchInitialize(on: subject)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 5)
        XCTAssertEqual(try recordedFigures(), [4, 5, 6, 7, 8])
        XCTAssertEqual(statsStore.highestReportedFiguresToReturn, 8)
    }

    // MARK: - Helpers

    private func createSubject(lifetimeTotal: Int) -> TrackerBlockerModuleMiddleware {
        statsStore.lifetimeTotalToReturn = lifetimeTotal
        return TrackerBlockerModuleMiddleware(
            statsStore: statsStore,
            telemetry: TrackerBlockerTelemetry(gleanWrapper: gleanWrapper)
        )
    }

    /// Runs an `initialize` action through the middleware and waits for the
    /// resulting count dispatch, by which point threshold telemetry (recorded
    /// synchronously before the dispatch) has already fired.
    private func dispatchInitialize(on subject: TrackerBlockerModuleMiddleware) {
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        let expectation = XCTestExpectation(description: "updateBlockedCount dispatched")
        mockStore.dispatchCalled = { expectation.fulfill() }

        subject.trackerBlockerModuleProvider.legacyMiddleware(AppState(), action)

        wait(for: [expectation])
    }

    private func recordedFigures() throws -> [Int32] {
        typealias ExtraType = GleanMetrics.TrackerBlocker.LifetimeThresholdReachedExtra
        return try gleanWrapper.savedExtras.map {
            try XCTUnwrap(($0 as? ExtraType)?.figures)
        }
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
    var highestReportedFiguresToReturn = 0

    func record(category: BlocklistCategory, count: Int, date: Date) {}
    func lifetimeTotal() -> Int { return lifetimeTotalToReturn }
    func lifetimeByCategory() -> [BlocklistCategory: Int] { return [:] }
    func currentWeekTotal(for date: Date) -> Int { return 0 }
    func currentWeekByCategory(for date: Date) -> [BlocklistCategory: Int] { return [:] }
    func trackingStartDate() -> Date? { return nil }
    func reset() {}
    func highestReportedFigures() -> Int { return highestReportedFiguresToReturn }
    func setHighestReportedFigures(_ figures: Int) { highestReportedFiguresToReturn = figures }
}
