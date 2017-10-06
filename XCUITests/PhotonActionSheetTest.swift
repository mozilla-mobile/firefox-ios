/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class PhotonActionSheetTest: BaseTestCase {
    var navigator: Navigator!
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
    }
    
    func testPinToTop() {
        navigator.openURL(urlString: "http://www.yahoo.com")
        
        // Open Action Sheet
        app.buttons["TabLocationView.pageOptionsButton"].tap()
        
        // Pin the site
        app.cells["Pin to Top Sites"].tap()
        
        // Verify that the site has been pinned
        
        // Open menu
        app.buttons["Menu"].tap()
        
        // Navigate to top sites
        app.cells["Top Sites"].tap()
        
        waitforExistence(app.cells["TopSite"].firstMatch)
        
        // Verify that the site is pinned to top
        let cell = app.cells["TopSite"].firstMatch
        XCTAssertEqual(cell.label, "yahoo")
        
        // Remove pin
        cell.press(forDuration: 2)
        app.cells["Remove Pinned Site"].tap()
    }
}
