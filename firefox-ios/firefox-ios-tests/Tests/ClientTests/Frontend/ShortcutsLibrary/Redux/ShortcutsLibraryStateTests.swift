// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage
import XCTest

@testable import Client

final class ShortcutsLibraryStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.shortcuts, [])
        XCTAssertFalse(initialState.shouldRecordImpressionTelemetry)
    }

    @MainActor
    func test_initializeAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = shortcutsLibraryReducer()

        let newState = reducer(
            initialState,
            ShortcutsLibraryAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: ShortcutsLibraryActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.shortcuts.count, initialState.shortcuts.count)
        XCTAssertTrue(newState.shouldRecordImpressionTelemetry)
    }

    @MainActor
    func test_impressionTelemetryRecordedAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = shortcutsLibraryReducer()

        let newState = reducer(
            initialState,
            ShortcutsLibraryAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: ShortcutsLibraryMiddlewareActionType.impressionTelemetryRecorded
            )
        )

        XCTAssertFalse(newState.shouldRecordImpressionTelemetry)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.shortcuts.count, initialState.shortcuts.count)
    }

    @MainActor
    func test_retrievedUpdatedSitesAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = shortcutsLibraryReducer()

        let exampleShortcut = TopSiteConfiguration(
            site: Site.createBasicSite(
                url: "https://www.example.com",
                title: "hello",
                isBookmarked: false
            )
        )

        let newState = reducer(
            initialState,
            TopSitesAction(
                topSites: [exampleShortcut],
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.shortcuts.count, 1)
        XCTAssertEqual(newState.shortcuts.compactMap { $0.title }, ["hello"])
    }

    @MainActor
    func test_retrievedUpdatedSitesAction_withEmptyShortcuts_returnsDefaultState() throws {
        let initialState = createSubject()
        let reducer = shortcutsLibraryReducer()

        let newState = reducer(
            initialState,
            TopSitesAction(
                topSites: nil,
                windowUUID: .XCTestDefaultUUID,
                actionType: TopSitesMiddlewareActionType.retrievedUpdatedSites
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)

        XCTAssertEqual(newState.shortcuts.count, 0)
        XCTAssertEqual(newState.shortcuts.compactMap { $0.title }, [])
        XCTAssertEqual(newState, defaultState(with: initialState))
        XCTAssertEqual(newState.shouldRecordImpressionTelemetry, initialState.shouldRecordImpressionTelemetry)
    }

    // MARK: - Private
    private func createSubject() -> ShortcutsLibraryState {
        return ShortcutsLibraryState(windowUUID: .XCTestDefaultUUID)
    }

    private func shortcutsLibraryReducer() -> Reducer<ShortcutsLibraryState> {
        return ShortcutsLibraryState.reducer
    }

    private func defaultState(with state: ShortcutsLibraryState) -> ShortcutsLibraryState {
        return ShortcutsLibraryState.defaultState(from: state)
    }
}
