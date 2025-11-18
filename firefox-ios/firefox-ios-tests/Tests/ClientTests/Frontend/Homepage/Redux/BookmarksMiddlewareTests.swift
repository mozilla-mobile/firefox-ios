// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class BookmarksMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockProfile: MockProfile!
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        mockProfile = nil
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func test_initializeAction_getBookmarksData() throws {
        let subject = createSubject()

        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        let expectation = XCTestExpectation(description: "Homepage action initialize dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.bookmarksProvider(AppState(), action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? BookmarksAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? BookmarksMiddlewareActionType)

        XCTAssertEqual(actionType, BookmarksMiddlewareActionType.initialize)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
    }

    func test_homepageMiddlewareAction_getBookmarksData() throws {
        let subject = createSubject()

        let action = HomepageAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: HomepageMiddlewareActionType.bookmarksUpdated
        )
        let expectation = XCTestExpectation(description: "Homepage action initialize dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.bookmarksProvider(AppState(), action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? BookmarksAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? BookmarksMiddlewareActionType)

        XCTAssertEqual(actionType, BookmarksMiddlewareActionType.initialize)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
    }

    // MARK: - Helpers
    private func createSubject() -> BookmarksMiddleware {
        return BookmarksMiddleware(profile: mockProfile)
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
