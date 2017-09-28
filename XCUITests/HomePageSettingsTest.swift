/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class HomePageSettingsTest: BaseTestCase {
    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // This test has moved from KIF UITest - accesses google.com instead of local webserver instance
    func testCurrentPage() {
        navigator.goto(BrowserTab)

        // Accessing https means that it is routed
        waitForValueContains(app.textFields["url"], value: "www.mozilla.org")
        let header = "https://" as? String
        let address = app.textFields["url"].value as? String
        let currentURL = header! + address!
        
        // Go via the menu, becuase if we go via the TabTray, then we 
        // won't have a current tab.
        navigator.goto(TabMenu)
        navigator.goto(HomePageSettings)
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Use Current Page"].tap()
        
        // check the value of the current homepage
        XCTAssertEqual(currentURL, app.tables.textFields["HomePageSettingTextField"].value as? String)
        tablesQuery.staticTexts["Clear"].tap()
        
        let urlString = app.tables.textFields["HomePageSettingTextField"].value ?? ""
        
        if iPad() {
            XCTAssertEqual("", urlString as! String)
        } else {
            XCTAssertEqual("Enter a webpage", urlString as! String)
        }
    }
    
    // Check whether the toolbar/menu shows homepage icon
    func testShowHomePageIcon() {
        navigator.goto(BrowserTab)
        
        // Accessing https means that it is routed
        waitForValueContains(app.textFields["url"], value: "www.mozilla.org")
        
        // Check the Homepage icon is present in menu by default
        navigator.goto(TabMenu)
        let collectionViewsQuery = app.collectionViews
        
        // Initially, there would be no Homepage icon since homepage is not set
        waitforNoExistence(collectionViewsQuery.cells["SetHomePageMenuItem"])
        
        // Go to settings, and set the homepage
        navigator.goto(HomePageSettings)
        app.tables/*@START_MENU_TOKEN@*/.staticTexts["Use Current Page"]/*[[".cells[\"Use Current Page\"].staticTexts[\"Use Current Page\"]",".cells[\"UseCurrentTab\"].staticTexts[\"Use Current Page\"]",".staticTexts[\"Use Current Page\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
       
        // Both pages do not show Homepage icon
        navigator.goto(TabMenu)
        waitforExistence(app/*@START_MENU_TOKEN@*/.tables["Context Menu"].staticTexts["Open Homepage"]/*[[".otherElements[\"Action Sheet\"].tables[\"Context Menu\"]",".cells[\"Open Homepage\"].staticTexts[\"Open Homepage\"]",".staticTexts[\"Open Homepage\"]",".tables[\"Context Menu\"]"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/)
        app/*@START_MENU_TOKEN@*/.tables["Context Menu"].staticTexts["Open Homepage"]/*[[".otherElements[\"Action Sheet\"].tables[\"Context Menu\"]",".cells[\"Open Homepage\"].staticTexts[\"Open Homepage\"]",".staticTexts[\"Open Homepage\"]",".tables[\"Context Menu\"]"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.tap()
        waitForValueContains(app.textFields["url"], value: "www.mozilla.org")
    }
}
