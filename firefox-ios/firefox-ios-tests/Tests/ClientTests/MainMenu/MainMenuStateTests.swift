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

        XCTAssertFalse(initialState.shouldDismiss)
        XCTAssertEqual(initialState.menuElements, [])
        XCTAssertNil(initialState.navigationDestination)
        XCTAssertNil(initialState.currentTabInfo)
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

        XCTAssertNil(initialState.currentTabInfo)

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

        XCTAssertNil(initialState.navigationDestination)

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

        XCTAssertFalse(initialState.shouldDismiss)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuActionType.toggleUserAgent
            )
        )

        XCTAssertTrue(newState.shouldDismiss)
    }

    func testCloseAction() {
        let initialState = createSubject()
        let reducer = mainMenuReducer()

        XCTAssertFalse(initialState.shouldDismiss)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuActionType.closeMenu
            )
        )

        XCTAssertTrue(newState.shouldDismiss)
    }

    // MARK: - Private
    private func createSubject() -> MainMenuState {
        return MainMenuState(windowUUID: .XCTestDefaultUUID)
    }

    private func mainMenuReducer() -> Reducer<MainMenuState> {
        return MainMenuState.reducer
    }
}
