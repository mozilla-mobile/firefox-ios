// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import XCTest

class DatabaseFixtureTest: BaseTestCase {
    let fixtures = ["testOneBookmark": "testDatabaseFixture-browser.db", "testBookmarksDatabaseFixture": "testBookmarksDatabase1000-browser.db", "testHistoryDatabaseFixture": "testHistoryDatabase4000-browser.db", "testHistoryDatabasePerformance": "testHistoryDatabase4000-browser.db", "testPerfHistory4000startUp": "testHistoryDatabase4000-browser.db", "testPerfHistory4000openMenu": "testHistoryDatabase4000-browser.db", "testPerfBookmarks1000openMenu": "testBookmarksDatabase1000-browser.db", "testPerfBookmarks1000startUp": "testBookmarksDatabase1000-browser.db"]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out the function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let key = String(parts[1])
        // for the current test name, add the db fixture used
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

    // Disabled due to #7789
    /*func testBookmarksDatabaseFixture() {
        waitForTabsButton()
        navigator.goto(MobileBookmarks)
        waitForExistence(app.tables["Bookmarks List"], timeout: 15)

        let loaded = NSPredicate(format: "count == 1013")
        expectation(for: loaded, evaluatedWith: app.tables["Bookmarks List"].cells, handler: nil)
        waitForExpectations(timeout: 60, handler: nil)

        let bookmarksList = app.tables["Bookmarks List"].cells.count
        XCTAssertEqual(bookmarksList, 1013, "There should be an entry in the bookmarks list")
    }*/

    func testHistoryDatabaseFixture() {
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 15)
        navigator.performAction(Action.CloseURLBarOpen)
        navigator.nowAt(NewTabScreen)
        navigator.goto(LibraryPanel_History)

        // History list has one cell that are for recently closed
        // the actual max number is 100
        let loaded = NSPredicate(format: "count == 101")
        expectation(for: loaded, evaluatedWith: app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView].cells, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }

    func testPerfHistory4000startUp() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // activity measurement here
            app.launch()
        }
    }

    func testPerfHistory4000openMenu() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // activity measurement here
            navigator.goto(LibraryPanel_History)
        }
    }

    func testPerfBookmarks1000startUp() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // activity measurement here
            app.launch()
        }
    }

    func testPerfBookmarks1000openMenu() {
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // activity measurement here
            navigator.goto(LibraryPanel_Bookmarks)
        }
    }
}
