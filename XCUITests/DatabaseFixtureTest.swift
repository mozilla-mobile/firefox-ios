/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class DatabaseFixtureTest: BaseTestCase {
    let fixtures = ["testOneBookmark": "testDatabaseFixture-browser.db", "testHistoryDatabaseFixture": "testHistoryDatabase4000-browser.db"]

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

    func testHistoryDatabaseFixture() {
        navigator.goto(HomePanel_History)
        // Small delay to avoid intermittent failures
        // Ideally, we would wait for the table to become populated, not sure how to do that.
        sleep(1)
        //History list has two cells that are for recently closed and synced devices that should not count as history items
        let historyList = app.tables["History List"].cells.count - 2
        XCTAssertEqual(historyList, 100, "There should be an entry in the bookmarks list")
    }
}
