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

    func test_initializeAction_getPocketData() {
        let subject = createSubject(pocketManager: pocketManager)
        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        let expectation = XCTestExpectation(description: "Homepage action initialize dispatched")

        mockStore.dispatchCalledCompletion = {
            expectation.fulfill()
        }

        subject.pocketSectionProvider(AppState(), action)

        wait(for: [expectation])

        guard let actionCalled = mockStore.dispatchCalled.withActions.first as? PocketAction,
              case PocketMiddlewareActionType.retrievedUpdatedStories = actionCalled.actionType else {
            XCTFail("Unexpected action type dispatched, \(String(describing: mockStore.dispatchCalled.withActions.first))")
            return
        }

        XCTAssertEqual(mockStore.dispatchCalled.numberOfTimes, 1)
        XCTAssertEqual(actionCalled.pocketStories?.count, 3)
        XCTAssertEqual(pocketManager.getPocketItemsCalled, 1)
    }

    func test_enterForegroundAction_getPocketData() {
        let subject = createSubject(pocketManager: pocketManager)
        let action = PocketAction(windowUUID: .XCTestDefaultUUID, actionType: PocketActionType.enteredForeground)

        let expectation = XCTestExpectation(description: "Pocket action entered foreground dispatched")
        mockStore.dispatchCalledCompletion = {
            expectation.fulfill()
        }

        subject.pocketSectionProvider(AppState(), action)

        wait(for: [expectation])

        guard let actionCalled = mockStore.dispatchCalled.withActions.first as? PocketAction,
              case PocketMiddlewareActionType.retrievedUpdatedStories = actionCalled.actionType else {
            XCTFail("Unexpected action type dispatched, \(String(describing: mockStore.dispatchCalled.withActions.first))")
            return
        }

        XCTAssertEqual(mockStore.dispatchCalled.numberOfTimes, 1)
        XCTAssertTrue(mockStore.dispatchCalled.withActions.first is PocketAction)
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
