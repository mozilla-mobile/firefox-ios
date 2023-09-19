// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class LibraryTestsIpad: IpadOnlyTestCase {
    func testLibraryShortcut() {
        if skipPlatform {return}
        // Open Library from shortcut
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.bookmarksButton])
        let libraryShorcutButton = app.buttons[AccessibilityIdentifiers.Toolbar.bookmarksButton]
        libraryShorcutButton.tap()
        navigator.nowAt(HomePanel_Library)
        mozWaitForElementToExist(app.tables["Bookmarks List"])
        // Go to a different panel, like History
        navigator.goto(LibraryPanel_History)
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView])
    }
}
