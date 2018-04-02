/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class DatabaseFixtureTest: BaseTestCase {
    let fixtures = ["testOneBookmark": "testDatabaseFixture-browser.db", "testBookmarksDatabaseFixture": "testBookmarksDatabase1000-browser.db", "testHistoryDatabaseFixture": "testHistoryDatabase4000-browser.db"]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name!.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        // for the current test name, add the db fixture used
        launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.LoadDatabasePrefix + fixtures[key]!]
        super.setUp()
    }

    func testOneBookmark() {
        navigator.browserPerformAction(.openBookMarksOption)
        let list = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(list, 1, "There should be an entry in the bookmarks list")
    }

    func testBookmarksDatabaseFixture() {
        navigator.goto(HomePanel_Bookmarks)

        let loaded = NSPredicate(format: "count == 1013")
        expectation(for: loaded, evaluatedWith: app.tables["Bookmarks List"].cells, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)

        let bookmarksList = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(bookmarksList, 1013, "There should be an entry in the bookmarks list")
    }

    func testHistoryDatabaseFixture() {
        navigator.goto(HomePanel_History)

        // History list has two cells that are for recently closed and synced devices that should not count as history items,
        // the actual max number is 100
        let loaded = NSPredicate(format: "count == 102")
        expectation(for: loaded, evaluatedWith: app.tables["History List"].cells, handler: nil)
        waitForExpectations(timeout: 5, handler: nil)
    }
}
