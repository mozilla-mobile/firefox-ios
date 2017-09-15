/* This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0. If a copy of the MPL was not distributed with this
 file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
class NightModeTests: BaseTestCase {
        
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
    
    private func nightModeOff() {
        waitforExistence(app.buttons["TabToolbar.menuButton"])
        app.buttons["TabToolbar.menuButton"].tap()
        waitforExistence(app.tables.cells["Night Mode: On"])
        app.tables.cells["Night Mode: On"].tap()
    }
    
    private func nightModeOn() {
        waitforExistence(app.buttons["TabToolbar.menuButton"])
        app.buttons["TabToolbar.menuButton"].tap()
        waitforExistence(app.tables.cells["Night Mode: Off"])
        app.tables.cells["Night Mode: Off"].tap()
    }
    
    private func checkNightModeOn() {
        waitforExistence(app.buttons["TabToolbar.menuButton"])
        app.buttons["TabToolbar.menuButton"].tap()
        waitforExistence(app.tables.cells["Night Mode: On"])
        app.buttons["Close"].tap()
    }
    
    private func checkNightModeOff() {
        waitforExistence(app.buttons["TabToolbar.menuButton"])
        app.buttons["TabToolbar.menuButton"].tap()
        waitforExistence(app.tables.cells["Night Mode: Off"])
        app.buttons["Close"].tap()
    }
    
    func testNightModeUI() {
        let url1 = "www.google.com"
        
        // Go to a webpage, and select night mode on and off, check it's applied or not
        navigator.openNewURL(urlString: url1)
        
        //turn on the night mode
        nightModeOn()
        
        //checking night mode on or off
        checkNightModeOn()
        
        //turn off the night mode
        nightModeOff()
        
        //checking night mode on or off
        checkNightModeOff()
    }
}
