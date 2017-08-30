/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class OpenInFocusTest : BaseTestCase {
    
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }

    override func tearDown() {
        XCUIApplication().terminate()
        super.tearDown()
    }

    func testOpenViaSafari() {
        let app = XCUIApplication()
        waitforExistence(element: app.textFields["URLBar.urlText"]) // wait for app.label
        let sharedExtName = app.label.contains("Klar") ? "Firefox Klar" : "Firefox Focus" as String
        
        XCUIDevice.shared().press(.home)
        let springboard = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.springboard")!
        waitforExistence(element: springboard.scrollViews.otherElements.icons[sharedExtName])

        let safariApp = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.mobilesafari")!
        safariApp.launchArguments = ["-u", "https://www.mozilla.org/en-US/"]
        safariApp.launch()
        
        safariApp.buttons["Share"].tap()
        safariApp.buttons["More"].tap()
        safariApp.tables.cells.containing(.staticText, identifier:sharedExtName).children(matching: .switch).matching(identifier: sharedExtName).element(boundBy: 0).tap()
        safariApp.navigationBars["Activities"].buttons["Done"].tap()
        safariApp.buttons[sharedExtName].tap()

        let focusApp = XCUIApplication()
        let addressBarField = focusApp.textFields["URLBar.urlText"]

        waitForValueContains(element: addressBarField, value: "https://www.mozilla.org/en-US/")
        waitforExistence(element: focusApp.buttons["ERASE"])  // check site is fully loaded
    }
}
