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
//        navigator.goto(SettingsScreen)

        waitforExistence(app.buttons["TabToolbar.menuButton"])
        app.buttons["TabToolbar.menuButton"].tap()
        waitforExistence(app.tables.cells["Settings"])
        app.tables.cells["Settings"].tap()

        waitforExistence(app.tables["AppSettingsTableViewController.tableView"].switches["Use Compact Tabs"])

        app.tables["AppSettingsTableViewController.tableView"].switches["Use Compact Tabs"].tap()
        app.buttons["Done"].tap()
        waitforNoExistence(app.staticTexts["Settings"])

        waitforExistence(app.buttons["URLBarView.tabsButton"])
        app/*@START_MENU_TOKEN@*/.buttons["URLBarView.tabsButton"]/*[[".buttons[\"Show Tabs\"]",".buttons[\"URLBarView.tabsButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        navigator.goto(TabTray)
        
        let exists = NSPredicate(format: "countForHittables == 4")
        expectation(for: exists, evaluatedWith: app.collectionViews.cells, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    //Set the compact mode to ON in settings screen
    private func compactModeOn() {
//        navigator.goto(SettingsScreen)
        waitforExistence(app.buttons["TabToolbar.menuButton"])
        app.buttons["TabToolbar.menuButton"].tap()
        waitforExistence(app.tables.cells["Settings"])
        app.tables.cells["Settings"].tap()
        
        waitforExistence(app.tables["AppSettingsTableViewController.tableView"].switches["Use Compact Tabs"])

        app.tables["AppSettingsTableViewController.tableView"].switches["Use Compact Tabs"].tap()
        app.buttons["Done"].tap()
        waitforNoExistence(app.staticTexts["Settings"])
        
        waitforExistence(app.buttons["URLBarView.tabsButton"])
        app/*@START_MENU_TOKEN@*/.buttons["URLBarView.tabsButton"]/*[[".buttons[\"Show Tabs\"]",".buttons[\"URLBarView.tabsButton\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

//        navigator.goto(TabTray)
        
        let exists = NSPredicate(format: "countForHittables == 6")
        expectation(for: exists, evaluatedWith: app.collectionViews.cells, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
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
                //openNewTab()
                navigator.createNewTab()
                loadWebPage(urls[i])
            }
            
            //Navigate to tabs tray
            navigator.goto(TabTray)
            
            //Wait until the cells show up
            //CollectionView visible cells count should be 6
            let exists = NSPredicate(format: "countForHittables == 6")
            expectation(for: exists, evaluatedWith: app.collectionViews.cells, handler: nil)
            waitForExpectations(timeout: 10, handler: nil)
            XCTAssertTrue(app.collectionViews.cells.countForHittables == 6)
            
            app.collectionViews.cells["Google"].tap()
            
            //CollectionView visible cells count should be less than or equal to 4
            compactModeOff()
            XCTAssertTrue(app.collectionViews.cells.countForHittables <= 4)
            
            app.collectionViews.cells["Google"].tap()

            //CollectionView visible cells count should be 6
            compactModeOn()
            XCTAssertTrue(app.collectionViews.cells.countForHittables == 6)
        }
    }
}

extension XCUIElementQuery {
    var countForHittables: UInt {
        return UInt(allElementsBoundByIndex.filter { $0.isHittable }.count)
    }
}
