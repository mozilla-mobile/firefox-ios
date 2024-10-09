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
                    "testPerfBookmarks1000startUp": "testBookmarksDatabase1000-places.db",
                    "testInactiveTabs": "tabsState20.archive"]

    override func setUp() {
        // Test name looks like: "[Class testFunc]", parse out function name
        let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
        let functionName = String(parts[1])
        // defaults
        launchArguments = [
            LaunchArguments.PerformanceTest,
            LaunchArguments.SkipIntro,
            LaunchArguments.SkipWhatsNew,
            LaunchArguments.SkipETPCoverSheet,
            LaunchArguments.SkipContextualHints,
            LaunchArguments.DisableAnimations
        ]
        // append specific load profiles to LaunchArguments
        if fixtures.keys.contains(functionName) {
            launchArguments.append(LaunchArguments.LoadTabsStateArchive + fixtures[functionName]!)
            launchArguments.append(LaunchArguments.LoadDatabasePrefix + fixtures[functionName]!)
        }
        super.setUp()
    }

    // This test run first to install the app in the device
    func testAppStart() {
        app.launch()
    }

    // https://mozilla.testrail.io/index.php?/cases/view/2307045
    func testInactiveTabs() {
        // Workaround to guarantee the tabs are loaded
        waitForTabsButton()
        waitUntilPageLoad()
        app.terminate()
        sleep(2)
        app.launch()

        // Confirm we have tabs loaded
        let tabsButtonNumber = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["20"]
        waitForTabsButton()
        mozWaitForElementToExist(tabsButtonNumber)
        waitUntilPageLoad()

        // Open Tab Tray
        navigator.goto(TabTray)

        // Inactive tabs list is displayed at the top
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Walmart | Save Money. Live better."])

        // Tap on the ">" button.
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."])
        app.buttons[AccessibilityIdentifiers.TabTray.doneButton].tap()

        // Go to Settings -> Tabs and disable "Inactive tabs"
        navigator.nowAt(NewTabScreen)
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.Settings.Tabs.title])
        app.cells[AccessibilityIdentifiers.Settings.Tabs.title].tap()
        mozWaitForElementToExist(app.tables.otherElements[AccessibilityIdentifiers.Settings.Tabs.Customize.title])
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].value as! String, "1")
        app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].tap()
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].value as! String, "0")
        app.navigationBars.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)

        // Return to tabs tray
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."])
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        app.buttons[AccessibilityIdentifiers.TabTray.doneButton].tap()
        navigator.nowAt(NewTabScreen)

        // Go to Settings -> Tabs and enable "Inactive tabs"
        navigator.goto(SettingsScreen)
        mozWaitForElementToExist(app.cells[AccessibilityIdentifiers.Settings.Tabs.title])
        app.cells[AccessibilityIdentifiers.Settings.Tabs.title].tap()
        mozWaitForElementToExist(app.tables.otherElements[AccessibilityIdentifiers.Settings.Tabs.Customize.title])
        app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].tap()
        XCTAssertEqual(
            app.switches[AccessibilityIdentifiers.Settings.Tabs.Customize.inactiveTabsSwitch].value as! String, "1")
        app.navigationBars.buttons["Settings"].tap()
        navigator.nowAt(SettingsScreen)

        // Return to tabs tray
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])

        // Tap on a tab from the inactive list
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        app.otherElements["Tabs Tray"].staticTexts["Homepage"].tap()
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"])

        navigator.nowAt(NewTabScreen)
        navigator.goto(TabTray)
        mozWaitForElementToExist(app.staticTexts["Homepage"])

        // Expand inactive list
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])
        app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView].tap()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])

        // Swipe on a tab from the list to delete
        app.otherElements["Tabs Tray"].staticTexts["Google"].swipeLeft()
        mozWaitForElementToExist(app.buttons["Close"])
        app.buttons["Close"].tap()
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."])

        // Tap "Close All Inactive Tabs"
        app.swipeUp()
        mozWaitForElementToExist(app.buttons["InactiveTabs.deleteButton"])
        app.buttons["InactiveTabs.deleteButton"].tap()
        mozWaitForElementToExist(app.staticTexts["Tabs Closed: 17"])

        // All inactive tabs are deleted
        navigator.nowAt(TabTray)
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Homepage"])
        mozWaitForElementToExist(app.otherElements["Tabs Tray"].staticTexts["Walmart | Save Money. Live better."])
        mozWaitForElementToNotExist(app.buttons[AccessibilityIdentifiers.TabTray.InactiveTabs.headerView])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Google"])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Facebook - log in or sign up"])
        mozWaitForElementToNotExist(app.otherElements["Tabs Tray"].staticTexts["Amazon.com. Spend less. Smile more."])
    }

    // 1 perf test per tabsStateArchive of size: 20, 1280
    // Taking the edges, low and high load. For more values in the middle
    // check the available archives
    func testPerfTabs_1_20startup() {
        app.terminate()
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // activity measurement here
            app.launch()
            app.terminate()
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfTabs_2_1280startup() {
        app.terminate()
        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // activity measurement here
            app.launch()
            app.terminate()
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfTabs_3_20tabTray() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        let tabsButtonNumber = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["20"]
        let doneButton = app.buttons[AccessibilityIdentifiers.TabTray.doneButton]

        mozWaitForElementToExist(tabsButton)
        mozWaitForElementToExist(tabsButtonNumber)

        measure(metrics: [
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // go to tab tray
            mozWaitForElementToExist(tabsButton)
            tabsButton.tap()
            mozWaitForElementToExist(doneButton)
            doneButton.tap()
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfTabs_4_1280tabTray() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        let tabsButtonNumber = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].staticTexts["∞"]
        let doneButton = app.buttons[AccessibilityIdentifiers.TabTray.doneButton]

        mozWaitForElementToExist(tabsButton)
        mozWaitForElementToExist(tabsButtonNumber)

        measure(metrics: [
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
            // go to tab tray
            mozWaitForElementToExist(tabsButton)
            tabsButton.tap()
            mozWaitForElementToExist(doneButton)
            doneButton.tap()
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfHistory1startUp() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)
        app.terminate()

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
                mozWaitForElementToExist(tabsButton)
                app.terminate()
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfHistory1openMenu() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)

        navigator.goto(LibraryPanel_History)

        // Ensure 'History List' exists before taking a snapshot to avoid expensive retries.
        // Return firstMatch to avoid traversing the entire { Window, Window } element tree.
        let historyList = app.tables["History List"].firstMatch
        mozWaitForElementToExist(historyList)

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // Include snapshot here as it is the closest approximation to an element load measurement
                do {
                    let historyListSnapshot = try historyList.snapshot()
                    let historyListCells = historyListSnapshot.children.filter { $0.elementType == .cell }
                    let historyItems = historyListCells.dropFirst()

                    // Warning: If the history database used for this test is updated, so will the date of
                    // those history items. This means as those history items age, they will fall into older
                    // buckets, causing new cells to be created representing this new age bucket
                    // (i.e. 'yesterday', 'a week', etc) where the 100 entries will be split across multiple age
                    // buckets. This will cause this test to fail as we are expecting exactly one age bucket
                    // for these to fail into. If this test fails because the actual count is 1 greater
                    // than expected, that is why.
                    XCTAssertEqual(historyItems.count, 1, "Number of cells in 'History List' is not equal to 1")
                } catch {
                    XCTFail("Failed to take snapshot: \(error)")
                }
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfHistory100startUp() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)
        app.terminate()

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
                mozWaitForElementToExist(tabsButton)
                app.terminate()
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfHistory100openMenu() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)

        navigator.goto(LibraryPanel_History)

        // Ensure 'History List' exists before taking a snapshot to avoid expensive retries.
        // Return firstMatch to avoid traversing the entire { Window, Window } element tree.
        let historyList = app.tables["History List"].firstMatch
        mozWaitForElementToExist(historyList)

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // Include snapshot here as it is the closest approximation to an element load measurement
                do {
                    let historyListSnapshot = try historyList.snapshot()
                    let historyListCells = historyListSnapshot.children.filter { $0.elementType == .cell }
                    let historyItems = historyListCells.dropFirst()

                    // Warning: If the history database used for this test is updated, so will the date of those
                    // history items. This means as those history items age, they will fall into older buckets,
                    // causing new cells to be created representing this new age bucket (i.e. 'yesterday',
                    // 'a week', etc) where the 100 entries will be split across multiple age buckets.
                    // This will cause this test to fail as we are expecting exactly one age bucket for these
                    // to fall into. If this test fails because the actual count is 1 greater than
                    // expected, that is why.
                    XCTAssertEqual(historyItems.count, 100, "Number of cells in 'History List' is not equal to 100")
                } catch {
                    XCTFail("Failed to take snapshot: \(error)")
                }
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfBookmarks1startUp() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)
        app.terminate()

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // activity measurement here
                app.launch()
                mozWaitForElementToExist(tabsButton)
                app.terminate()
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfBookmarks1openMenu() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)

        navigator.goto(LibraryPanel_Bookmarks)

        // Ensure 'Bookmarks List' exists before taking a snapshot to avoid expensive retries.
        // Return firstMatch to avoid traversing the entire { Window, Window } element tree.
        let bookmarksList = app.tables["Bookmarks List"].firstMatch
        mozWaitForElementToExist(bookmarksList)

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // Include snapshot here as it is the closest approximation to an element load measurement
                // Take a manual snapshot to avoid unnecessary snapshots by xctrunner (~9s each).
                // Filter out 'Other' elements and drop 'Desktop Bookmarks' cell for a true bookmark count.
                do {
                    // Activity measurement here
                    let bookmarksListSnapshot = try bookmarksList.snapshot()
                    let bookmarksListCells = bookmarksListSnapshot.children.filter { $0.elementType == .cell }
                    let bookmarks = bookmarksListCells.dropFirst()

                    XCTAssertEqual(bookmarks.count, 1, "Number of cells in 'Bookmarks List' is not equal to 1")
                } catch {
                    XCTFail("Failed to take snapshot: \(error)")
                }
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfBookmarks100startUp() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)
        app.terminate()

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // Activity measurement here
                app.launch()
                mozWaitForElementToExist(tabsButton)
                app.terminate()
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfBookmarks100openMenu() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)

        navigator.goto(LibraryPanel_Bookmarks)

        // Ensure 'Bookmarks List' exists before taking a snapshot to avoid expensive retries.
        // Return firstMatch to avoid traversing the entire { Window, Window } element tree.
        let bookmarksList = app.tables["Bookmarks List"].firstMatch
        mozWaitForElementToExist(bookmarksList)

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // Include snapshot here as it is the closest approximation to an element load measurement
                // Take a manual snapshot to avoid unnecessary snapshots by xctrunner (~9s each).
                // Filter out 'Other' elements and drop 'Desktop Bookmarks' cell for a true bookmark count.
                do {
                    let bookmarksListSnapshot = try bookmarksList.snapshot()
                    let bookmarksListCells = bookmarksListSnapshot.children.filter { $0.elementType == .cell }
                    let bookmarks = bookmarksListCells.dropFirst()

                    // Activity measurement here
                    XCTAssertEqual(bookmarks.count, 100, "Number of cells in 'Bookmarks List' is not equal to 100")
                } catch {
                    XCTFail("Failed to take a snapshot: \(error)")
                }
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfBookmarks1000startUp() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)
        app.terminate()

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure cpu cycles
            XCTStorageMetric(), // to measure storage consuming
            XCTMemoryMetric()]) {
                // Activity measurement here
                app.launch()
                mozWaitForElementToExist(tabsButton)
                app.terminate()
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }

    func testPerfBookmarks1000openMenu() {
        // Warning: Avoid using mozWaitForElementToExist as it is up to 25x less performant
        let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        mozWaitForElementToExist(tabsButton)

        navigator.goto(LibraryPanel_Bookmarks)

        // Ensure 'Bookmarks List' exists before taking a snapshot to avoid expensive retries.
        // Return firstMatch to avoid traversing the entire { Window, Window } element tree.
        let bookmarksList = app.tables["Bookmarks List"].firstMatch
        mozWaitForElementToExist(bookmarksList)

        measure(metrics: [
            XCTMemoryMetric(),
            XCTClockMetric(), // to measure timeClock Mon
            XCTCPUMetric(), // to measure CPU cycles
            XCTStorageMetric(), // to measure storage consumption
            XCTMemoryMetric()]) {
                // Include snapshot here as it is the closest approximation to an element load measurement
                // Take a manual snapshot to avoid unnecessary snapshots by xctrunner (~9s each).
                // Filter out 'Other' elements and drop 'Desktop Bookmarks' cell for a true bookmark count.
                do {
                    // Activity measurement here
                    let bookmarksListSnapshot = try bookmarksList.snapshot()
                    let bookmarksListCells = bookmarksListSnapshot.children.filter { $0.elementType == .cell }
                    let bookmarks = bookmarksListCells.dropFirst()

                    XCTAssertEqual(bookmarks.count, 1000, "Number of cells in 'Bookmarks List' is not equal to 1000")
                } catch {
                    XCTFail("Failed to take a snapshot: \(error)")
                }
        }
        // Handle termination ourselves as it sometimes hangs when given to xctrunner
        app.terminate()
    }
}
