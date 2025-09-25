// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class LibraryScreen {
    private let app: XCUIApplication
    private let sel: LibrarySelectorsSet

    init(app: XCUIApplication, selectors: LibrarySelectorsSet = LibrarySelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertBookmarkExists(named name: String, timeout: TimeInterval = TIMEOUT_LONG) {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)

        // Wait for the table and the specific bookmark to exist.
        BaseTestCase().waitForElementsToExist([
            bookmarksTable,
            bookmarksTable.staticTexts[name]
        ], timeout: timeout)
    }
}
