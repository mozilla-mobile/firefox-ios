// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class LibraryTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2306889
    func testLibraryShortcut() {
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        // The Bookmark panel is displayed
        navigator.nowAt(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.LibraryPanels.BookmarksPanel.tableView])
        // Go to a different panel
        // The History Panel is displayed
        navigator.nowAt(HomePanel_Library)
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
