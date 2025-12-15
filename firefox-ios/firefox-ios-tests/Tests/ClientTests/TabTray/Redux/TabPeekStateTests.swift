// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class TabPeekStateTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    @MainActor
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

    @MainActor
    func testLoadTabPeekAction_showRemoveBookmark_andSendToDevice() {
        let initialState = createSubject()
        let reducer = tabPeekReducer()

        XCTAssertEqual(initialState.showRemoveBookmark, false)
        XCTAssertEqual(initialState.showSendToDevice, false)

        let action = getAction(for: .loadTabPeek)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showRemoveBookmark, true)
        XCTAssertEqual(newState.showSendToDevice, true)
    }

    @MainActor
    func testLoadTabPeekAction_doesNotShowAddBookmarks_orSendToDevice() {
        let initialState = createSubject()
        let reducer = tabPeekReducer()

        XCTAssertEqual(initialState.showAddToBookmarks, false)
        XCTAssertEqual(initialState.showSendToDevice, false)

        let model = TabPeekModel(
            canTabBeSaved: false,
            canTabBeRemoved: false,
            canCopyURL: true,
            isSyncEnabled: true,
            screenshot: UIImage(),
            accessiblityLabel: ""
        )
        let action = getAction(for: .loadTabPeek, with: model)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showAddToBookmarks, false)
        XCTAssertEqual(newState.showSendToDevice, false)
    }

    @MainActor
    func testLoadTabPeekAction_doesNotShowRemoveBookmark_orSendToDevice() {
        let initialState = createSubject()
        let reducer = tabPeekReducer()

        XCTAssertEqual(initialState.showRemoveBookmark, false)
        XCTAssertEqual(initialState.showSendToDevice, false)

        let model = TabPeekModel(
            canTabBeSaved: false,
            canTabBeRemoved: false,
            canCopyURL: true,
            isSyncEnabled: true,
            screenshot: UIImage(),
            accessiblityLabel: ""
        )
        let action = getAction(for: .loadTabPeek, with: model)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.showRemoveBookmark, false)
        XCTAssertEqual(newState.showSendToDevice, false)
    }

    @MainActor
    func testLoadTabPeekAction_showBookmarks_andDoesNotShowDevice() {
        let initialState = createSubject()
        let reducer = tabPeekReducer()

        XCTAssertEqual(initialState.showAddToBookmarks, false)
        XCTAssertEqual(initialState.showSendToDevice, false)

        let model = TabPeekModel(
            canTabBeSaved: true,
            canTabBeRemoved: false,
            canCopyURL: true,
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
            canTabBeRemoved: true,
            canCopyURL: true,
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
