// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class JumpBackInSectionStateTests: XCTestCase {
    var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
    }

    override func tearDown() {
        mockProfile = nil
        super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.jumpBackInTabs, [])
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = jumpBackInSectionReducer()

        let newState = reducer(
            initialState,
            TabManagerAction(
                recentTabs: [createTab(urlString: "www.mozilla.org")],
                windowUUID: .XCTestDefaultUUID,
                actionType: TabManagerMiddlewareActionType.fetchRecentTabs
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.jumpBackInTabs.count, 1)
        XCTAssertEqual(newState.jumpBackInTabs.first?.titleText, "www.mozilla.org")
        XCTAssertEqual(newState.jumpBackInTabs.first?.descriptionText, "Www.Mozilla.Org")
        XCTAssertEqual(newState.jumpBackInTabs.first?.siteURL, "www.mozilla.org")
        XCTAssertEqual(newState.jumpBackInTabs.first?.accessibilityLabel, "www.mozilla.org, Www.Mozilla.Org")
    }

    // MARK: - Private
    private func createSubject() -> JumpBackInSectionState {
        return JumpBackInSectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func jumpBackInSectionReducer() -> Reducer<JumpBackInSectionState> {
        return JumpBackInSectionState.reducer
    }

    func createTab(urlString: String) -> Tab {
        let tab = Tab(profile: mockProfile, windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: urlString)!
        return tab
    }
}
