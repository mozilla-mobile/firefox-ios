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
        DependencyHelperMock().reset()
        super.tearDown()
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
            tabID: "1234",
            url: URL(string: "https://mozilla.com"),
            isHomepage: true,
            isDefaultUserAgentDesktop: true,
            hasChangedUserAgent: true,
            readerModeIsAvailable: false,
            isBookmarked: false,
            isInReadingList: false,
            isPinned: false
        )

        XCTAssertNil(initialState.currentTabInfo)

        let newState = reducer(
            initialState,
            MainMenuAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: MainMenuActionType.updateCurrentTabInfo,
                currentTabInfo: expectedResult
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
                    actionType: MainMenuActionType.tapNavigateToDestination,
                    navigationDestination: MenuNavigationDestination(destination)
                )
            )

            guard let currentDestination = newState.navigationDestination?.destination else {
                return XCTFail("Execting to find a destination, but it was nil")
            }

            XCTAssertEqual(currentDestination, destination)
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
                actionType: MainMenuActionType.tapToggleUserAgent
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
                actionType: MainMenuActionType.tapCloseMenu
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
