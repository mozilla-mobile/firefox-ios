// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common

@testable import Client

final class TabWebViewPreviewStateTests: XCTestCase, StoreTestUtility {
    let windowUUID: WindowUUID = .XCTestDefaultUUID

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

    func test_initialState_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .unavailable)
        XCTAssertEqual(initialState.searchBarPosition, .top)
        XCTAssertNil(initialState.screenshot)
    }

    func test_didLoadToolbarsActionAndToolbarPositionChangedAction_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()
        let didLoadToolbarsAction = ToolbarAction(
            toolbarPosition: .bottom,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.didLoadToolbars
        )
        let toolbarPositionChangedAction = ToolbarAction(
            toolbarPosition: .top,
            windowUUID: windowUUID,
            actionType: ToolbarActionType.toolbarPositionChanged
        )

        let newState = TabWebViewPreviewState.reducer(initialState, didLoadToolbarsAction)

        XCTAssertEqual(newState.windowUUID, .unavailable)
        XCTAssertEqual(newState.searchBarPosition, .bottom)
        XCTAssertNotEqual(initialState.searchBarPosition, newState.searchBarPosition)

        let newState2 = TabWebViewPreviewState.reducer(initialState, toolbarPositionChangedAction)

        XCTAssertEqual(newState2.windowUUID, .unavailable)
        XCTAssertEqual(newState2.searchBarPosition, .top)
        XCTAssertNotEqual(newState.searchBarPosition, newState2.searchBarPosition)
    }

    func test_didTakeScreenshotAction_returnsExpectedState() {
        setupStore()
        let initialState = createSubject()

        let newState = TabWebViewPreviewState.reducer(
            initialState,
            TabWebViewPreviewAction(
                screenshot: UIImage(),
                actionType: TabWebViewPreviewActionType.didTakeScreenshot
            )
        )

        XCTAssertEqual(initialState.windowUUID, newState.windowUUID)
        XCTAssertEqual(initialState.searchBarPosition, newState.searchBarPosition)
        XCTAssertNotEqual(initialState.screenshot, newState.screenshot)
        XCTAssertNotNil(newState.screenshot)
    }

    // MARK: - Helpers
    private func createSubject() -> TabWebViewPreviewState {
        return TabWebViewPreviewState()
    }

    // MARK: - StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .tabWebViewPreview(TabWebViewPreviewState())
                ]
            )
        )
    }

    func setupStore() {
        StoreTestUtilityHelper.setupStore(
            with: setupAppState(),
            middlewares: []
        )
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
