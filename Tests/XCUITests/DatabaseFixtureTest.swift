// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class DatabaseFixtureTest: BaseTestCase {
    let fixtures = ["testBookmarksDatabaseFixture": "testBookmarksDatabase1000-places.db", "testHistoryDatabaseFixture": "testHistoryDatabase4000-places.db", "testPerfHistory100startUp": "testHistoryDatabase4000-places.db", "testPerfHistory100openMenu": "testHistoryDatabase4000-places.db", "testPerfBookmarks1000openMenu": "testBookmarksDatabase1000-places.db", "testPerfBookmarks1000startUp": "testBookmarksDatabase1000-places.db"]

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

        // History list has one cell that are for recently closed
        // the actual max number is 100
        let loaded = NSPredicate(format: "count == 101")
        expectation(for: loaded, evaluatedWith: app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView].cells, handler: nil)
        waitForExpectations(timeout: TIMEOUT, handler: nil)
        let historyList = app.tables["History List"].cells.count
        XCTAssertEqual(historyList, 101, "There should be 101 entries in the history list")
    }

    func testPerfHistory100startUp() {
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

    func testPerfHistory100openMenu() {
        app.launch()
        waitForTabsButton()
        navigator.goto(BrowserTabMenu)
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // activity measurement here
            waitForExistence(app.tables.otherElements[ImageIdentifiers.Large.history], timeout: TIMEOUT)
            app.tables.otherElements[ImageIdentifiers.Large.history].tap()
                
            let loaded = NSPredicate(format: "count == 101")
            expectation(for: loaded, evaluatedWith: app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView].cells, handler: nil)
            waitForExpectations(timeout: TIMEOUT, handler: nil)
                
            app.buttons["Done"].tap()
            waitForTabsButton()
            navigator.nowAt(NewTabScreen)
            navigator.goto(BrowserTabMenu)
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
        app.launch()
        waitForTabsButton()
        navigator.goto(BrowserTabMenu)
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // activity measurement here
                
                waitForExistence(app.tables.otherElements[ImageIdentifiers.Large.bookmarkTrayFill], timeout: TIMEOUT)
                app.tables.otherElements[ImageIdentifiers.Large.bookmarkTrayFill].tap()
                
                let loaded = NSPredicate(format: "count == 1001")
                expectation(for: loaded, evaluatedWith: app.tables["Bookmarks List"].cells, handler: nil)
                waitForExpectations(timeout: TIMEOUT_LONG, handler: nil)
                
                app.buttons["Done"].tap()
                waitForTabsButton()
                navigator.nowAt(NewTabScreen)
                navigator.goto(BrowserTabMenu)
        }
    }
}
