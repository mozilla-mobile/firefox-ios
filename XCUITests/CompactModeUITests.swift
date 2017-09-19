/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class CompactModeUITests: BaseTestCase {
    
    var navigator: Navigator!
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }
    
    override func tearDown() {
        navigator = nil
        app = nil
        super.tearDown()
    }
    
    //Set the compact mode to OFF in settings screen
    private func compactModeOff() {
        waitforExistence(app.buttons["TabToolbar.menuButton"])
        navigator.goto(SettingsScreen)

        let compactSwitch = app.tables["AppSettingsTableViewController.tableView"].switches["Use Compact Tabs"]
        compactSwitch.tap()
        XCTAssertEqual(compactSwitch.value as? String, "0")
    }
    
    //Set the compact mode to ON in settings screen
    private func compactModeOn() {
        waitforExistence(app.buttons["TabToolbar.menuButton"])
        navigator.goto(SettingsScreen)
        
        let compactSwitch = app.tables["AppSettingsTableViewController.tableView"].switches["Use Compact Tabs"]
        compactSwitch.tap()
        XCTAssertEqual(compactSwitch.value as? String, "1")
    }
    
    func testCompactModeUI() {
        if !iPad() {
            //Dsimiss intro screen
            dismissFirstRunUI()
            
            //Creating array of 6 urls
            let urls: [String] = [
                "www.google.com",
                "www.facebook.com",
                "www.youtube.com",
                "www.amazon.com",
                "www.twitter.com",
               "www.yahoo.com"
            ]
            
            //Open the array of urls in 6 different tabs
            loadWebPage(urls[0])
            for i in 1..<urls.count {
                navigator.createNewTab()
                loadWebPage(urls[i])
            }
            
            //Navigate to tabs tray
            //CollectionView visible cells count should be 6
            navigator.goto(TabTray)
            var exists = NSPredicate(format: "countForHittables == 6")
            expectation(for: exists, evaluatedWith: app.collectionViews.cells, handler: nil)
            waitForExpectations(timeout: 10, handler: nil)
            XCTAssertTrue(app.collectionViews.cells.countForHittables == 6)
            
            // Go to one of the tabs to access menu
            app.collectionViews.cells["Google"].tap()
            navigator.nowAt(BrowserTab)
            
            //CollectionView visible cells count should be less than or equal to 4
            compactModeOff()
            navigator.goto(TabTray)
            exists = NSPredicate(format: "countForHittables == 4")
            expectation(for: exists, evaluatedWith: app.collectionViews.cells, handler: nil)
            waitForExpectations(timeout: 10, handler: nil)
            
            // Go to one of the tabs to access menu
            app.collectionViews.cells["Google"].tap()
            navigator.nowAt(BrowserTab)
            
            //CollectionView visible cells count should be 6
            compactModeOn()
            navigator.goto(TabTray)
            exists = NSPredicate(format: "countForHittables == 6")
            expectation(for: exists, evaluatedWith: app.collectionViews.cells, handler: nil)
            waitForExpectations(timeout: 10, handler: nil)
        }
    }
}

extension XCUIElementQuery {
    var countForHittables: UInt {
        return UInt(allElementsBoundByIndex.filter { $0.isHittable }.count)
    }
}
