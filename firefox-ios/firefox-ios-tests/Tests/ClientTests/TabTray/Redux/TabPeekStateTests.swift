// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class TabPeekStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func testLoadTabPeekAction_showAddBookmarks_andSendToDevice() {
        let initialState = createSubject()
        let reducer = tabPeekReducer()

        XCTAssertEqual(initialState.showAddToBookmarks, false)
        XCTAssertEqual(initialState.showSendToDevice, false)

        let action = getAction(for: .loadTabPeek)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showAddToBookmarks, true)
        XCTAssertEqual(newState.showSendToDevice, true)
    }

    func testLoadTabPeekAction_doesNotShowAddBookmarks_orSendToDevice() {
        let initialState = createSubject()
        let reducer = tabPeekReducer()

        XCTAssertEqual(initialState.showAddToBookmarks, false)
        XCTAssertEqual(initialState.showSendToDevice, false)

        let model = TabPeekModel(
            canTabBeSaved: false,
            isSyncEnabled: true,
            screenshot: UIImage(),
            accessiblityLabel: ""
        )
        let action = getAction(for: .loadTabPeek, with: model)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showAddToBookmarks, false)
        XCTAssertEqual(newState.showSendToDevice, false)
    }

    func testLoadTabPeekAction_showBookmarks_andDoesNotShowDevice() {
        let initialState = createSubject()
        let reducer = tabPeekReducer()

        XCTAssertEqual(initialState.showAddToBookmarks, false)
        XCTAssertEqual(initialState.showSendToDevice, false)

        let model = TabPeekModel(
            canTabBeSaved: true,
            isSyncEnabled: false,
            screenshot: UIImage(),
            accessiblityLabel: ""
        )
        let action = getAction(for: .loadTabPeek, with: model)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showAddToBookmarks, true)
        XCTAssertEqual(newState.showSendToDevice, false)
    }

    // MARK: - Private
    private func createSubject() -> TabPeekState {
        return TabPeekState(windowUUID: .XCTestDefaultUUID)
    }

    private func tabPeekReducer() -> Reducer<TabPeekState> {
        return TabPeekState.reducer
    }

    private func getAction(
        for actionType: TabPeekActionType,
        with model: TabPeekModel = TabPeekModel(
            canTabBeSaved: true,
            isSyncEnabled: true,
            screenshot: UIImage(),
            accessiblityLabel: "tabpeek-a11y-label"
        )
    ) -> TabPeekAction {
        return TabPeekAction(
            tabPeekModel: model,
            windowUUID: .XCTestDefaultUUID,
            actionType: actionType
        )
    }
}
