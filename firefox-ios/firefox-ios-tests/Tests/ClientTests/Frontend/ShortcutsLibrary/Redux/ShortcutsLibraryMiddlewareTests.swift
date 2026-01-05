// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import Redux
import XCTest

@testable import Client

final class ShortcutsLibraryMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockGleanWrapper: MockGleanWrapper!
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        mockGleanWrapper = MockGleanWrapper()
        setupStore()
    }

    override func tearDown() async throws {
        mockGleanWrapper = nil
        resetStore()
        try await super.tearDown()
    }

    func test_viewDidAppearAction_sendsTelemetryData_whenShouldRecordImpressionTelemetry_isTrue() throws {
        let initialState = setupShortcutsLibraryStateForTelemetry()

        let subject = createSubject()
        let action = ShortcutsLibraryAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.viewDidAppear
        )

        subject.shortcutsLibraryProvider(initialState, action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.HomepageShortcutsLibrary.viewed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_viewDidAppearAction_doesNotSendTelemetryData_whenShouldRecordImpressionTelemetry_isFalse() throws {
        let subject = createSubject()
        let action = ShortcutsLibraryAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.viewDidAppear
        )

        subject.shortcutsLibraryProvider(AppState(), action)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 0)
    }

    func test_viewDidDisappearAction_sendsTelemetryData() throws {
        let subject = createSubject()
        let action = ShortcutsLibraryAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.viewDidDisappear
        )

        subject.shortcutsLibraryProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.HomepageShortcutsLibrary.closed)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    func test_tapOnShortcutCellAction_sendsTelemetryData() throws {
        let subject = createSubject()
        let action = ShortcutsLibraryAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.tapOnShortcutCell
        )

        subject.shortcutsLibraryProvider(AppState(), action)

        let savedMetric = try XCTUnwrap(mockGleanWrapper.savedEvents.first as? EventMetricType<NoExtras>)
        let expectedMetricType = type(of: GleanMetrics.HomepageShortcutsLibrary.shortcutTapped)
        let resultMetricType = type(of: savedMetric)
        let debugMessage = TelemetryDebugMessage(expectedMetric: expectedMetricType, resultMetric: resultMetricType)

        XCTAssertEqual(mockGleanWrapper.recordEventNoExtraCalled, 1)
        XCTAssert(resultMetricType == expectedMetricType, debugMessage.text)
    }

    // MARK: - Helpers
    private func createSubject() -> ShortcutsLibraryMiddleware {
        return ShortcutsLibraryMiddleware(
            shortcutsLibraryTelemetry: ShortcutsLibraryTelemetry(
                gleanWrapper: mockGleanWrapper
            )
        )
    }

    private func shortcutsLibraryReducer() -> Reducer<ShortcutsLibraryState> {
        return ShortcutsLibraryState.reducer
    }

    private func setupShortcutsLibraryShouldRecordImpressionTelemetryAppState() -> AppState {
        let initialState = ShortcutsLibraryState(windowUUID: .XCTestDefaultUUID)
        let reducer = shortcutsLibraryReducer()
        let action = ShortcutsLibraryAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ShortcutsLibraryActionType.initialize
        )
        let newState = reducer(initialState, action)

        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .shortcutsLibrary(newState)
                ]
            )
        )
    }

    private func setupShortcutsLibraryStateForTelemetry() -> AppState {
        mockStore = MockStoreForMiddleware(state: setupShortcutsLibraryShouldRecordImpressionTelemetryAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
        return mockStore.state
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .shortcutsLibrary(
                        ShortcutsLibraryState(
                            windowUUID: .DefaultUITestingUUID
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
