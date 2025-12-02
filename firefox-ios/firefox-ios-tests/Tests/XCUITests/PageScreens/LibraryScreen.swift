// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
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

    func assertBookmarkList() {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)
        BaseTestCase().mozWaitForElementToExist(bookmarksTable)
    }

    func assertBookmarkListCount(numberOfEntries: Int) {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)
        XCTAssertEqual(bookmarksTable.cells.count, numberOfEntries)
    }

    func swipeBookmarkEntry(entryName: String) {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)
        bookmarksTable.cells.staticTexts[entryName].swipeLeft()
    }

    func tapDeleteBookmarkButton() {
        let deleteButton = sel.DELETE_BUTTON.element(in: app)
        deleteButton.waitAndTap()
    }

    func swipeAndDeleteBookmark(entryName: String) {
        swipeBookmarkEntry(entryName: entryName)
        tapDeleteBookmarkButton()
    }

    func assertEmptyStateSignInButtonExists() {
        BaseTestCase().mozWaitForElementToExist(sel.SIGN_IN_BUTTON.element(in: app))
    }

    func assertBookmarkListLabel(label: String) {
        let bookmarksTable = sel.BOOKMARKS_LIST.element(in: app)
        XCTAssertEqual(bookmarksTable.label, "Empty list")
    }
}
