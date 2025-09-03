// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

final class ShortcutsLibraryViewControllerTests: XCTestCase, StoreTestUtility {
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

    func test_viewDidLoad_triggersShortcutsLibraryAction() throws {
        let subject = createSubject()

        subject.viewDidLoad()

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is ShortcutsLibraryAction }) as? ShortcutsLibraryAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? ShortcutsLibraryActionType)
        XCTAssertEqual(actionType, ShortcutsLibraryActionType.initialize)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_viewDidAppear_triggersShortcutsLibraryAction() throws {
        let subject = createSubject()

        subject.viewDidAppear(false)

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is ShortcutsLibraryAction }) as? ShortcutsLibraryAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? ShortcutsLibraryActionType)
        XCTAssertEqual(actionType, ShortcutsLibraryActionType.viewDidAppear)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    func test_viewDidDisappear_triggersShortcutsLibraryAction() throws {
        let subject = createSubject()

        subject.viewDidDisappear(false)

        let actionCalled = try XCTUnwrap(
            mockStore.dispatchedActions.last(where: { $0 is ShortcutsLibraryAction }) as? ShortcutsLibraryAction
        )
        let actionType = try XCTUnwrap(actionCalled.actionType as? ShortcutsLibraryActionType)
        XCTAssertEqual(actionType, ShortcutsLibraryActionType.viewDidDisappear)
        XCTAssertEqual(actionCalled.windowUUID, .XCTestDefaultUUID)
    }

    private func createSubject(statusBarScrollDelegate: StatusBarScrollDelegate? = nil) -> ShortcutsLibraryViewController {
        let shortcutsLibraryViewController = ShortcutsLibraryViewController(windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(shortcutsLibraryViewController)
        return shortcutsLibraryViewController
    }

    func setupAppState() -> Client.AppState {
        return AppState()
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
