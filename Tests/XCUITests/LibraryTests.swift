// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class LibraryTestsIpad: IpadOnlyTestCase {

    func testLibraryShortcut() {
        if skipPlatform {return}
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 3)
        navigator.performAction(Action.CloseURLBarOpen)
        // Open Library from shortcut
        waitForExistence(app.buttons["TabToolbar.libraryButton"])
        let libraryShorcutButton = app.buttons["TabToolbar.libraryButton"]
        libraryShorcutButton.tap()
        navigator.nowAt(HomePanel_Library)
        waitForExistence(app.tables["Bookmarks List"])
        // Go to a different panel, like History
        navigator.goto(LibraryPanel_History)
        waitForExistence(app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView])
    }
}
