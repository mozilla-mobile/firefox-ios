// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MainMenuDetailsStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testInitialization() {
        let initialState = createSubject()

        XCTAssertFalse(initialState.shouldDismiss)
        XCTAssertFalse(initialState.shouldGoBackToMainMenu)
        XCTAssertEqual(initialState.menuElements, [])
        XCTAssertNil(initialState.navigationDestination)
        XCTAssertNil(initialState.submenuType)
    }

    func testUpdatingCurrentTabInfo() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuDetailsActionType.dismissView
            )
        )

        XCTAssertTrue(newState.shouldDismiss)
    }

    func testNavigation_ForEditBookmark() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuDetailsActionType.editBookmark,
                navigationDestination: MenuNavigationDestination(.editBookmark)
            )
        )

        guard let currentDestination = newState.navigationDestination?.destination else {
            return XCTFail("Execting to find a destination, but it was nil")
        }

        XCTAssertEqual(currentDestination, .editBookmark)
    }

    func testCloseAction() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertFalse(initialState.shouldGoBackToMainMenu)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuDetailsActionType.backToMainMenu
            )
        )

        XCTAssertTrue(newState.shouldGoBackToMainMenu)
    }

    func testAddBookmarkAction() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertFalse(initialState.shouldDismiss)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuDetailsActionType.addToBookmarks
            )
        )

        XCTAssertTrue(newState.shouldDismiss)
    }

    func testAddToShortcutsAction() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertFalse(initialState.shouldDismiss)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuDetailsActionType.addToShortcuts
            )
        )

        XCTAssertTrue(newState.shouldDismiss)
    }

    func testAddToReadingListAction() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertFalse(initialState.shouldDismiss)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuDetailsActionType.addToReadingList
            )
        )

        XCTAssertTrue(newState.shouldDismiss)
    }

    func testRemoveFromShorcuts() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertFalse(initialState.shouldDismiss)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuDetailsActionType.removeFromShortcuts
            )
        )

        XCTAssertTrue(newState.shouldDismiss)
    }

    func testRemoveFromReadingList() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertFalse(initialState.shouldDismiss)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuDetailsActionType.removeFromReadingList
            )
        )

        XCTAssertTrue(newState.shouldDismiss)
    }

    // MARK: - Private
    private func createSubject() -> MainMenuDetailsState {
        return MainMenuDetailsState(windowUUID: .XCTestDefaultUUID)
    }

    private func mainMenuReducer() -> Reducer<MainMenuDetailsState> {
        return MainMenuDetailsState.reducer
    }
}
