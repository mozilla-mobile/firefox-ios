// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class DatabaseFixtureTest: BaseTestCase {
    let fixtures = ["testBookmarksDatabaseFixture": "testBookmarksDatabase1000-places.db", "testHistoryDatabaseFixture": "testHistoryDatabase100-places.db"]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        launchArguments = [LaunchArguments.SkipIntro,
                           LaunchArguments.SkipWhatsNew,
                           LaunchArguments.SkipETPCoverSheet,
                           LaunchArguments.LoadDatabasePrefix + fixtures[key]!,
                           LaunchArguments.SkipContextualHints,
                           LaunchArguments.TurnOffTabGroupsInUserPreferences]
        super.setUp()
    }

    /* Disabled due to issue with db: 8281*/
    /*func testOneBookmark() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Bookmarks)
        waitForExistence(app.cells.staticTexts["Mobile Bookmarks"], timeout: 5)
        navigator.goto(MobileBookmarks)
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
    }*/

   func testBookmarksDatabaseFixture() {
       waitForTabsButton()
       navigator.goto(LibraryPanel_Bookmarks)
       waitForExistence(app.tables["Bookmarks List"], timeout: TIMEOUT_LONG)

       let loaded = NSPredicate(format: "count == 1001")
       expectation(for: loaded, evaluatedWith: app.tables["Bookmarks List"].cells, handler: nil)
       waitForExpectations(timeout: TIMEOUT_LONG, handler: nil)

       let bookmarksList = app.tables["Bookmarks List"].cells.count
       XCTAssertEqual(bookmarksList, 1001, "There should be an entry in the bookmarks list")
   }

   func testHistoryDatabaseFixture() throws {
       waitForTabsButton()
       navigator.goto(LibraryPanel_History)
       waitForExistence(app.tables["History List"], timeout: TIMEOUT_LONG)
       // History list has one cell that are for recently closed
       // the actual max number is 101
       let loaded = NSPredicate(format: "count == 101")
       expectation(for: loaded, evaluatedWith: app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView].cells, handler: nil)
       waitForExpectations(timeout: TIMEOUT, handler: nil)
       let historyList = app.tables["History List"].cells.count
       XCTAssertEqual(historyList, 101, "There should be 101 entries in the history list")
   }
}
