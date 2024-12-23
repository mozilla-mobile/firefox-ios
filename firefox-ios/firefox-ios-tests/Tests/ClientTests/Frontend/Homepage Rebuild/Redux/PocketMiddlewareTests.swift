// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class PocketMiddlewareTests: XCTestCase, StoreTestUtility {
    let pocketManager = MockPocketManager()
    var mockStore: MockStoreForMiddleware<AppState>!

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
        let action = PocketAction(windowUUID: .XCTestDefaultUUID, actionType: PocketActionType.enteredForeground)

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

    // MARK: - Helpers
    private func createSubject(pocketManager: MockPocketManager) -> PocketMiddleware {
        return PocketMiddleware(pocketManager: pocketManager)
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
