// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class PocketMiddlewareTests: XCTestCase, StoreTestUtility {
    let storeUtilityHelper = StoreTestUtilityHelper()
    let pocketManager = MockPocketManager()
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedPocketManager: pocketManager)
        setupTestingStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetTestingStore()
        super.tearDown()
    }

    func test_initializeAction_getPocketData() async throws {
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        store.dispatch(action)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let homepageState = store.state.screenState(
            HomepageState.self,
            for: .homepage,
            window: .XCTestDefaultUUID
        )
        XCTAssertNotNil(homepageState)
        XCTAssertEqual(homepageState?.pocketState.pocketData.count, 3)
        XCTAssertEqual(pocketManager.getPocketItemsCalled, 1)
    }

    func test_enterForegroundAction_getPocketData() async throws {
        let action = PocketAction(windowUUID: .XCTestDefaultUUID, actionType: PocketActionType.enteredForeground)
        store.dispatch(action)
        try await Task.sleep(nanoseconds: 1_000_000_000)

        let homepageState = store.state.screenState(
            HomepageState.self,
            for: .homepage,
            window: .XCTestDefaultUUID
        )
        XCTAssertNotNil(homepageState)
        XCTAssertEqual(homepageState?.pocketState.pocketData.count, 3)
        XCTAssertEqual(pocketManager.getPocketItemsCalled, 1)
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

    func setupTestingStore() {
        storeUtilityHelper.setupTestingStore(
            with: setupAppState(),
            middlewares: [PocketMiddleware().pocketSectionProvider]
        )
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetTestingStore() {
        storeUtilityHelper.resetTestingStore()
    }
}
