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
        app.terminate()
        super.tearDown()
    }

    func testOpenViaSafari() {
        waitforHittable(element: app.textFields["URLBar.urlText"]) // wait for app.label
        let sharedExtName = app.label.contains("Klar") ? "Firefox Klar" : "Firefox Focus" as String
        
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.springboard")!
        waitforHittable(element: springboard.scrollViews.otherElements.icons[sharedExtName])

        let safariApp = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.mobilesafari")!
        safariApp.launchArguments = ["-u", "https://www.google.com"]
        safariApp.launch()

        // Need to wait for the site to load as well as the share buttn availability
        waitforExistence(element: safariApp.buttons["Google Search"])

        waitforEnable(element: safariApp.buttons["Share"])
        safariApp.buttons["Share"].tap()
        waitforEnable(element: safariApp.collectionViews.cells.buttons["More"])
        safariApp.collectionViews.cells.buttons["More"].tap()
        
        // in iOS 10.3.1, multiple elements are found with 'Firefox Focus' label
        let firefoxFocusSwitch = safariApp.tables.switches.matching(identifier: sharedExtName).element(boundBy: 0)
        waitforHittable(element: firefoxFocusSwitch)
        firefoxFocusSwitch.tap()
        safariApp.navigationBars["Activities"].buttons["Done"].tap()
        waitforExistence(element: safariApp.buttons[sharedExtName])
        safariApp.buttons[sharedExtName].tap()

        let focusApp = XCUIApplication()
        let addressBarField = focusApp.textFields["URLBar.urlText"]
        waitForWebPageLoad()
        waitforExistence(element: focusApp.images["Google"])
        waitForValueContains(element: addressBarField, value: "https://www.google")
        waitforExistence(element: focusApp.buttons["ERASE"])  // check site is fully loaded
    }
}
