// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class BookmarksSectionStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.bookmarks, [])
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = bookmarksSectionReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.bookmarks.count, 1)

        XCTAssertEqual(newState.bookmarks.first?.site.url, "www.mozilla.org")
        XCTAssertEqual(newState.bookmarks.first?.site.title, "Bookmarks Title")
        XCTAssertEqual(newState.bookmarks.first?.accessibilityLabel, "Bookmarks Title")
    }

    // MARK: - Private
    private func createSubject() -> BookmarksSectionState {
        return BookmarksSectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func bookmarksSectionReducer() -> Reducer<BookmarksSectionState> {
        return BookmarksSectionState.reducer
    }
}
