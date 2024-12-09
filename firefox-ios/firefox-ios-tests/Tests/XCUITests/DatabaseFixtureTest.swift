// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

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

    // https://mozilla.testrail.io/index.php?/cases/view/2458579
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

    // https://mozilla.testrail.io/index.php?/cases/view/2459133
   func testHistoryDatabaseFixture() throws {
       let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
       mozWaitForElementToExist(tabsButton)

       navigator.goto(LibraryPanel_History)

       let historyList = app.tables["History List"].firstMatch
       mozWaitForElementToExist(historyList)

       do {
           let snapshot = try app.tables["History List"].snapshot()
           let historyList = snapshot.children.count
           if #available(iOS 18, *) {
               XCTAssertEqual(historyList, 105, "There should be 105 entries in the history list")
           } else {
               // For iOS 18, the scrollbars (vertical and horizontal) are included in the table
               XCTAssertEqual(historyList, 103, "There should be 103 entries in the history list")
           }
       } catch {
           XCTFail("Failed to take snapshot: \(error)")
       }

       app.terminate()
   }
}
