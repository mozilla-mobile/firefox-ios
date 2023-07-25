// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

class PerformanceTests: BaseTestCase {
    let fixtures = ["testPerfTabs_1_20startup": "tabsState20.archive",
                    "testPerfTabs_3_20tabTray": "tabsState20.archive",
                    "testPerfTabs_2_1280startup": "tabsState1280.archive",
                    "testPerfTabs_4_1280tabTray": "tabsState1280.archive",
                    "testPerfHistory1startUp": "testHistoryDatabase1-places.db",
                    "testPerfHistory1openMenu": "testHistoryDatabase1-places.db",
                    "testPerfHistory100startUp": "testHistoryDatabase100-places.db",
                    "testPerfHistory100openMenu": "testHistoryDatabase100-places.db",
                    "testPerfBookmarks1startUp": "testBookmarksDatabase1-places.db",
                    "testPerfBookmarks1openMenu": "testBookmarksDatabase1-places.db",
                    "testPerfBookmarks100startUp": "testBookmarksDatabase100-places.db",
                    "testPerfBookmarks100openMenu": "testBookmarksDatabase100-places.db",
                    "testPerfBookmarks1000openMenu": "testBookmarksDatabase1000-places.db",
                    "testPerfBookmarks1000startUp": "testBookmarksDatabase1000-places.db"]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let functionName = String(parts[1])
        // defaults
        launchArguments = [LaunchArguments.PerformanceTest, LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, LaunchArguments.SkipContextualHints]

        // append specific load profiles to LaunchArguments
        if fixtures.keys.contains(functionName) {
            launchArguments.append(LaunchArguments.LoadTabsStateArchive + fixtures[functionName]!)
            launchArguments.append(LaunchArguments.LoadDatabasePrefix + fixtures[functionName]!)
        }
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    // This test run first to install the app in the device
    func testAppStart() {
        app.launch()
    }

    // 1 perf test per tabsStateArchive of size: 20, 1280
    // Taking the edges, low and high load. For more values in the middle
    // check the available archives
    func testPerfTabs_1_20startup() {
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

    func testPerfTabs_2_1280startup() {
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

    func testPerfTabs_3_20tabTray() {
        app.launch()
        waitForTabsButton()
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["20"], timeout: TIMEOUT_LONG)

        measure(metrics: [
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // go to tab tray
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: TIMEOUT_LONG)
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
            waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.doneButton])
            app.buttons[AccessibilityIdentifiers.TabTray.doneButton].tap()
        }
    }

    func testPerfTabs_4_1280tabTray() {
        app.launch()
        waitForTabsButton()
        waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["∞"], timeout: TIMEOUT_LONG)
        measure(metrics: [
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // go to tab tray
            waitForExistence(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton])
            app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].tap()
            waitForExistence(app.buttons[AccessibilityIdentifiers.TabTray.doneButton])
            app.buttons[AccessibilityIdentifiers.TabTray.doneButton].tap()
        }
    }

    // Additional Scenarios
    // 1. Start app
    // 2. Open tabs Tray
    // 3. Open 1 new tab
    // 4. Close 1 tab
    // 5. Close all tabs
    // 6. Switch to private browsing
    // 7. Switch back from private browsing
    // 8. Create new tab in private browsing

    // This can be used for generating new tabs
    /*
    func testTabs5Setup() {
        let archiveSize = 1080
        let fileName = "/Users/rpappalax/git/firefox-ios-TABS-PERF-WIP/Client/Assets/topdomains.txt"
        var contents = ""
        var urls = [String]()
        do {
            contents = try String(contentsOfFile: fileName)
            urls = contents.components(separatedBy: "\n")
        } catch {
            print("COULDNT LOAD")
        }
        navigator.goto(NewTabScreen)
        var counter = 0
        let topDomainsCount = urls.count
        //for url in urls {
        for n in 0...archiveSize {
            print(urls[counter])
            if (counter >= archiveSize) {
                break
            }
            // if we don't have enough urls, start from the beginning of list
            if (counter >= (topDomainsCount - 1)) {
                counter = 0
            }
            counter += 1
        }
    }*/

    func testPerfHistory1startUp() {
        waitForTabsButton()
        app.terminate()
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
                waitForTabsButton()
        }
    }

    func testPerfHistory1openMenu() {
        waitForTabsButton()
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                navigator.goto(LibraryPanel_History)
                let historyList = app.tables["History List"]
                waitForExistence(historyList, timeout: TIMEOUT_LONG)
                let expectedCount = 2
                XCTAssertEqual(historyList.cells.count, expectedCount, "Number of cells in 'History List' is not equal to \(expectedCount)")
        }
    }

    func testPerfHistory100startUp() {
        waitForTabsButton()
        app.terminate()
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
                waitForTabsButton()
        }
    }

    func testPerfHistory100openMenu() {
        waitForTabsButton()
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                navigator.goto(LibraryPanel_History)
                let historyList = app.tables["History List"]
                waitForExistence(historyList, timeout: TIMEOUT_LONG)
                let expectedCount = 101
                XCTAssertEqual(historyList.cells.count, expectedCount, "Number of cells in 'History List' is not equal to \(expectedCount)")
        }
    }

    func testPerfBookmarks1startUp() {
        waitForTabsButton()
        app.terminate()
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
                waitForTabsButton()
        }
    }

    func testPerfBookmarks1openMenu() {
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                let bookmarkTable = app.tables["Bookmarks List"]
                waitForExistence(bookmarkTable, timeout: TIMEOUT_LONG)
                let expectedCount = 2
                XCTAssertEqual(bookmarkTable.cells.count, expectedCount, "Number of cells in 'Bookmarks List' is not equal to \(expectedCount)")
        }
    }

    func testPerfBookmarks100startUp() {
        waitForTabsButton()
        app.terminate()
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
                waitForTabsButton()
        }
    }

    func testPerfBookmarks100openMenu() {
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                let bookmarkTable = app.tables["Bookmarks List"]
                waitForExistence(bookmarkTable, timeout: TIMEOUT_LONG)
                let expectedCount = 101
                XCTAssertEqual(bookmarkTable.cells.count, expectedCount, "Number of cells in 'Bookmarks List' is not equal to \(expectedCount)")
        }
    }

    func testPerfBookmarks1000startUp() {
        waitForTabsButton()
        app.terminate()
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
                waitForTabsButton()
        }
    }

    func testPerfBookmarks1000openMenu() {
        waitForTabsButton()
        navigator.goto(LibraryPanel_Bookmarks)
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                let bookmarkTable = app.tables["Bookmarks List"]
                waitForExistence(bookmarkTable, timeout: TIMEOUT_LONG)
                let expectedCount = 1001
                XCTAssertEqual(bookmarkTable.cells.count, expectedCount, "Number of cells in 'Bookmarks List' is not equal to \(expectedCount)")
        }
    }
}
