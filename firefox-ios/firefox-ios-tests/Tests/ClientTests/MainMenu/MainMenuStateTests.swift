// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MainMenuStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        super.tearDown()
        DependencyHelperMock().reset()
    }

    func testInitialization() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertEqual(initialState.shouldDismiss, false)
        XCTAssertEqual(initialState.menuElements, [])
        XCTAssertEqual(initialState.navigationDestination, nil)
        XCTAssertEqual(initialState.currentTabInfo, nil)
    }

    func testUpdatingCurrentTabInfo() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        let expectedResult = MainMenuTabInfo(
            url: URL(string: "https://mozilla.com"),
            isHomepage: true,
            isDefaultUserAgentDesktop: true,
            hasChangedUserAgent: true
        )

        XCTAssertEqual(initialState.currentTabInfo, nil)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuActionType.updateCurrentTabInfo(expectedResult)
            )
        )

        XCTAssertEqual(newState.currentTabInfo, expectedResult)
    }

    func testNavigation_AllCases() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertEqual(initialState.navigationDestination, nil)

        MainMenuNavigationDestination.allCases.forEach { destination in
            let newState = reducer(
                initialState,
                MainMenuAction(
                    windowUUID: .XCTestDefaultUUID,
                    actionType: MainMenuActionType.show(destination)
                )
            )

            XCTAssertEqual(newState.navigationDestination, destination)
        }
    }

    func testToggleUserAgentAction() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertEqual(initialState.shouldDismiss, false)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuActionType.toggleUserAgent
            )
        )

        XCTAssertEqual(newState.shouldDismiss, true)
    }

    func testCloseAction() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertEqual(initialState.shouldDismiss, false)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuActionType.closeMenu
            )
        )

        XCTAssertEqual(newState.shouldDismiss, true)
    }

    // MARK: - Private
    private func createSubject() -> MainMenuState {
        return MainMenuState(windowUUID: .XCTestDefaultUUID)
    }

    private func mainMenuReducer() -> Reducer<MainMenuState> {
        return MainMenuState.reducer
    }
}
