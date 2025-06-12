// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class PocketMiddlewareTests: XCTestCase, StoreTestUtility {
    let pocketManager = MockPocketManager()
    var mockGleanWrapper: MockGleanWrapper!
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() {
        super.setUp()
        mockGleanWrapper = MockGleanWrapper()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        mockGleanWrapper = nil
        resetStore()
        super.tearDown()
    }

    func test_initializeAction_getPocketData() throws {
        let subject = createSubject(pocketManager: pocketManager)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        let expectation = XCTestExpectation(description: "Homepage action initialize dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.pocketSectionProvider(AppState(), action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? PocketAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? PocketMiddlewareActionType)

        XCTAssertEqual(actionType, PocketMiddlewareActionType.retrievedUpdatedStories)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionCalled.pocketStories?.count, 3)
        XCTAssertEqual(pocketManager.getPocketItemsCalled, 1)
    }

    func test_enterForegroundAction_getPocketData() throws {
        let subject = createSubject(pocketManager: pocketManager)
        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.enteredForeground
        )

        let expectation = XCTestExpectation(description: "Pocket action entered foreground dispatched")
        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.pocketSectionProvider(AppState(), action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? PocketAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? PocketMiddlewareActionType)

        XCTAssertEqual(actionType, PocketMiddlewareActionType.retrievedUpdatedStories)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertTrue(mockStore.dispatchedActions.first is PocketAction)
        XCTAssertEqual(actionCalled.pocketStories?.count, 3)
        XCTAssertEqual(pocketManager.getPocketItemsCalled, 1)
    }

    func test_tapOnHomepagePocketCellAction_sendTelemetryData() throws {
        let subject = createSubject(pocketManager: pocketManager)
        let config = OpenPocketTelemetryConfig(isZeroSearch: false, position: 0)
        let action = PocketAction(
            telemetryConfig: config,
            windowUUID: .XCTestDefaultUUID,
            actionType: PocketActionType.tapOnHomepagePocketCell
        )
        subject.pocketSectionProvider(AppState(), action)

        let firstSavedMetric = try XCTUnwrap(
            mockGleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>
        )
        let expectedFirstMetricType = type(of: GleanMetrics.Pocket.openStoryOrigin)
        let firstResultMetricType = type(of: firstSavedMetric)
        let debugMessage = TelemetryDebugMessage(
            expectedMetric: expectedFirstMetricType,
            resultMetric: firstResultMetricType
        )

        let secondSavedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? LabeledMetricType<CounterMetricType>)
        let expectedSecondMetricType = type(of: GleanMetrics.Pocket.openStoryPosition)
        let secondResultMetricType = type(of: secondSavedMetric)
        let secondDebugMessage = TelemetryDebugMessage(
            expectedMetric: expectedSecondMetricType,
            resultMetric: secondResultMetricType
        )

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 2)
        XCTAssertEqual(mockGleanWrapper.recordLabelCalled, 2)
        XCTAssert(firstResultMetricType == expectedFirstMetricType, debugMessage.text)
        XCTAssert(secondResultMetricType == expectedSecondMetricType, secondDebugMessage.text)
    }

    func test_tapOnHomepagePocketCell_doesNotSendTelemetryData() throws {
        let subject = createSubject(pocketManager: pocketManager)
        let action = PocketAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: PocketActionType.tapOnHomepagePocketCell
        )
        subject.pocketSectionProvider(AppState(), action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordLabelCalled, 0)
    }

    func test_viewedSectionAction_sendTelemetryData() throws {
        let subject = createSubject(pocketManager: pocketManager)
        let action = PocketAction(windowUUID: .XCTestDefaultUUID, actionType: PocketActionType.viewedSection)

        subject.pocketSectionProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? CounterMetricType)
        let expectedMetricType = type(of: GleanMetrics.Pocket.sectionImpressions)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.incrementCounterCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_tappedOnOpenNewPrivateTabAction_sendTelemetryData() throws {
        let subject = createSubject(pocketManager: pocketManager)
        let action = ContextMenuAction(
            section: .pocket(nil),
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnOpenNewPrivateTab
        )
        subject.pocketSectionProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.Pocket.openInPrivateTab)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_tappedOnOpenNewPrivateTabAction_doesNotSendTelemetryData() {
        let subject = createSubject(pocketManager: pocketManager)
        let action = ContextMenuAction(
            section: .topSites(4),
            windowUUID: .XCTestDefaultUUID,
            actionType: ContextMenuActionType.tappedOnOpenNewPrivateTab
        )
        subject.pocketSectionProvider(AppState(), action)

        XCTAssertEqual(mockGleanWrapper.savedEvents.count, 0)
        XCTAssertEqual(mockGleanWrapper.recordEventCalled, 0)
    }

    // MARK: - Helpers
    private func createSubject(pocketManager: MockPocketManager) -> PocketMiddleware {
        return PocketMiddleware(
            pocketManager: pocketManager,
            homepageTelemetry: HomepageTelemetry(
                gleanWrapper: mockGleanWrapper
            )
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
