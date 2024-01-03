// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class DatabaseFixtureTest: BaseTestCase {
    let fixtures = [
        "testBookmarksDatabaseFixture": "testBookmarksDatabase1000-places.db",
        "testHistoryDatabaseFixture": "testHistoryDatabase100-places.db"
    ]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        launchArguments = [LaunchArguments.SkipIntro,
                           LaunchArguments.SkipWhatsNew,
                           LaunchArguments.SkipETPCoverSheet,
                           LaunchArguments.LoadDatabasePrefix + fixtures[key]!,
                           LaunchArguments.SkipContextualHints,
                           LaunchArguments.DisableAnimations]
        super.setUp()
    }

    /* Disabled due to issue with db: 8281*/
    /*func testOneBookmark() {
        mozWaitForElementToExist(app.buttons["urlBar-cancel"], timeout: 5)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_Bookmarks)
        mozWaitForElementToExist(app.cells.staticTexts["Mobile Bookmarks"], timeout: 5)
        navigator.goto(MobileBookmarks)
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
    }*/

    func testBookmarksDatabaseFixture() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)

        navigator.goto(LibraryPanel_Bookmarks)

        // Ensure 'Bookmarks List' exists before taking a snapshot to avoid expensive retries.
        // Return firstMatch to avoid traversing the entire { Window, Window } element tree.
        let bookmarksList = app.tables["Bookmarks List"].firstMatch
        mozWaitForElementToExist(bookmarksList)

        do {
            // Take a custom snapshot to avoid unnecessary snapshots by xctrunner (~9s each).
            // Filter out 'Other' elements and drop the 'Desktop Bookmarks' cell for a true bookmark count.
            let bookmarksListSnapshot = try bookmarksList.snapshot()
            let bookmarksListCells = bookmarksListSnapshot.children.filter { $0.elementType == .cell }
            let filteredBookmarksList = bookmarksListCells.dropFirst()

            XCTAssertEqual(filteredBookmarksList.count, 1000, "There should be 1000 entries in the bookmarks list")
        } catch {
            XCTFail("Failed to take snapshot: \(error)")
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

   func testHistoryDatabaseFixture() throws {
       let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
       mozWaitForElementToExist(tabsButton)

       navigator.goto(LibraryPanel_History)

       let historyList = app.tables["History List"].firstMatch
       mozWaitForElementToExist(historyList)

       do {
           let snapshot = try app.tables["History List"].snapshot()
           let historyList = snapshot.children.count

           XCTAssertEqual(historyList, 103, "There should be 103 entries in the history list")
       } catch {
           XCTFail("Failed to take snapshot: \(error)")
       }

       app.terminate()
   }
}
