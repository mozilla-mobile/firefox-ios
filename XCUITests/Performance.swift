/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class Performance: BaseTestCase {
    
    let testFixtures = ["testPerfOpenAppHistory": "testHistoryDatabase4000-browser.db", "testPerfOpenAppBookmarks": "testBookmarksDatabase1000-browser.db"]
    let testNames = ["testPerfOpenAppHistory", "testPerfOpenAppBookmarks"]
    
    override func setUp() {
            // Test name looks like: "[Class testFunc]", parse out the function name
            let parts = name.replacingOccurrences(of: "]", with: "").split(separator: " ")
            let key = String(parts[1])
            // for the current test name, add the db fixture used
            
        if (testNames.contains(key)){
            launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet, LaunchArguments.LoadDatabasePrefix + testFixtures[key]!]
        } else {
            launchArguments = [LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew, LaunchArguments.SkipETPCoverSheet]
        }
            super.setUp()
    }
    // Test opening two tabs different than HomePanelsSecreen
    func testPerformanceTabTray() {
        // Open two tabs and go to tab tray
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"))
        waitForTabsButton()
        navigator.openNewURL(urlString: secondURL)
        waitForTabsButton()
        
        // If we just go to Tab Tray then the average time is around 0.1 seconds
        // If we add a check to be sure we are in the Tab Tray, the the average is around 1 second
        self.measure {
            navigator.goto(TabTray)
            // Should we add one of these checks to be sure Tab Tray is loaded correctly?
            //waitForExistence(app.textFields["Search Tabs"])
            waitForExistence(app.collectionViews.cells["The Book of Mozilla"])
        }
    }

    // Open tabs tray without tabs
    func testPerfOpenTabsTrayWithoutTabs() {
        if #available(iOS 13.0, *) {
            measure(metrics: [
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                    navigator.goto(TabTray)
            }
        }
    }
    
    // Open tabs tray without tabs -> open a new one
    func testPerfOpenTabsTrayWithoutTabsThenOneTab() {
        if #available(iOS 13.0, *) {
            measure(metrics: [
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                    // navigator.goto(TabTray)
                    navigator.performAction(Action.OpenNewTabFromTabTray)
            }
        }
    }
    
    // objective: (1) find the error threshold
    // (2)find where perf degrades
    // -- Open tabs tray with 5 tabs
    // -- Open tabs tray with 10 tabs
    // -- Open tabs tray with 15 tabs
    // -- Open tabs tray with 20 tabs
    // -- Open tabs tray with 25 tabs
    // -- Open tabs tray with 50 tabs
    func testPerfOpenTabsTrayWithCumulativeTabIncrease() {
        navigator.goto(TabTray)
        for _ in 1...3 {
            app.buttons["TabTrayController.addTabButton"].tap()
            navigator.nowAt(NewTabScreen)
            navigator.goto(TabTray)
        }
        navigator.performAction(Action.OpenNewTabFromTabTray)
        navigator.nowAt(HomePanelsScreen)
        if #available(iOS 13.0, *) {
            measure(metrics: [
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                    navigator.goto(TabTray)
            }
        }
        
//        // 2nd bulk
//        navigator.performAction(Action.OpenNewTabFromTabTray)
//        navigator.nowAt(HomePanelsScreen)
//
//        if #available(iOS 13.0, *) {
//            measure(metrics: [
//                XCTClockMetric(), // to measure timeClock Mon
//                XCTCPUMetric(), // to measure cpu cycles
//                XCTStorageMetric(), // to measure storage consuming
//                XCTMemoryMetric()]) {
//                    navigator.goto(TabTray)
//            }
//        }
    }
    
    func testPerfOpenAppHistory() {
        if #available(iOS 13.0, *) {
            measure(metrics: [
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                    app.launch()
            }
        }
    }
    
    func testPerfOpenApp() {
        if #available(iOS 13.0, *) {
            measure(metrics: [
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                    app.launch()
            }
        }
    }
    
    func testPerfOpenAppBookmarks() {
        if #available(iOS 13.0, *) {
            measure(metrics: [
                XCTClockMetric(), // to measure timeClock Mon
                XCTCPUMetric(), // to measure cpu cycles
                XCTStorageMetric(), // to measure storage consuming
                XCTMemoryMetric()]) {
                    app.launch()
            }
        }
    }
    
}
