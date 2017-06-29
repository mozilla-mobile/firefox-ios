/* This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
        navigator.goto(SettingsScreen)
        app.tables["AppSettingsTableViewController.tableView"].switches["Use Compact Tabs"].tap()
        navigator.goto(TabTray)
    }
    
    //Set the compact mode to ON in settings screen
    private func compactModeOn() {
        navigator.goto(SettingsScreen)
        app.tables["AppSettingsTableViewController.tableView"].switches["Use Compact Tabs"].tap()
        navigator.goto(TabTray)
    }
    
    func testCompactModeUI() {
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
        let exists = NSPredicate(format: "countForHittables > 1")
        expectation(for: exists, evaluatedWith: app.collectionViews.cells, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        XCTAssertTrue(app.collectionViews.cells.countForHittables == 6)
        
        compactModeOff()
        
        //CollectionView visible cells count should be less than or equal to 4
        XCTAssertTrue(app.collectionViews.cells.countForHittables <= 4)
        
        compactModeOn()
        
        //CollectionView visible cells count should be 6
        XCTAssertTrue(app.collectionViews.cells.countForHittables == 6)
    }
}

extension XCUIElementQuery {
    var countForHittables: UInt {
        return UInt(allElementsBoundByIndex.filter { $0.isHittable }.count)
    }
}
