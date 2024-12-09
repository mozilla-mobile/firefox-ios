// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class LibraryTestsIpad: IpadOnlyTestCase {
    func testLibraryShortcut() throws {
        guard !iPad() else {
            throw XCTSkip("Library shortcut not available on the new toolbar for iPad")
        }
        if skipPlatform {return}
        // Open Library from shortcut
        // The Bookmark panel is displayed
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.bookmarksButton])
        let libraryShorcutButton = app.buttons[AccessibilityIdentifiers.Toolbar.bookmarksButton]
        libraryShorcutButton.tap()
        navigator.nowAt(HomePanel_Library)
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.tableView])
        // Go to a different panel
        // The History Panel is displayed
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView])
        // The Downloads panel is displayed
        navigator.nowAt(HomePanel_Library)
        navigator.goto(LibraryPanel_Downloads)
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.LibraryPanels.DownloadsPanel.tableView])
        // The Reading List panel is displayed
        navigator.nowAt(HomePanel_Library)
        navigator.goto(LibraryPanel_ReadingList)
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.LibraryPanels.ReadingListPanel.tableView])
    }
}
