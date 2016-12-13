/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class BaseTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        restart(app)
    }

    override func tearDown() {
        super.tearDown()
    }

    func restart(app: XCUIApplication) {
        app.terminate()
        app.launchArguments.append(LaunchArguments.Test)
        app.launchArguments.append(LaunchArguments.ClearProfile)
        app.launch()
        sleep(1)
    }
    
    //If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().buttons["Start Browsing"]
        
        if (firstRunUI.exists) {
            firstRunUI.tap()
        }
    }
    
    func waitforExistence(element: XCUIElement) {
        let exists = NSPredicate(format: "exists == true")
        
        expectationForPredicate(exists, evaluatedWithObject: element, handler: nil)
        waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func waitforNoExistence(element: XCUIElement) {
        let exists = NSPredicate(format: "exists != true")
        
        expectationForPredicate(exists, evaluatedWithObject: element, handler: nil)
        waitForExpectationsWithTimeout(20, handler: nil)
    }
    
    func waitForValueContains(element: XCUIElement, value: String) {
        let predicateText = "value CONTAINS " + "'" + value + "'"
        let valueCheck = NSPredicate(format: predicateText)
        
        expectationForPredicate(valueCheck, evaluatedWithObject: element, handler: nil)
        waitForExpectationsWithTimeout(20, handler: nil)
    }

    func loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        let loaded = NSPredicate(format: "value BEGINSWITH '100'")

        let app = XCUIApplication()

        UIPasteboard.generalPasteboard().string = url
        app.textFields["url"].pressForDuration(2.0)
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()

        if waitForLoadToFinish {
            let finishLoadingTimeout: NSTimeInterval = 30
            
            let progressIndicator = app.progressIndicators.elementBoundByIndex(0)
            expectationForPredicate(loaded, evaluatedWithObject: progressIndicator, handler: nil)
            waitForExpectationsWithTimeout(finishLoadingTimeout, handler: nil)
        }
    }

}

extension BaseTestCase {
    func tabTrayButton(forApp app: XCUIApplication) -> XCUIElement {
        return app.buttons["TopTabsViewController.tabsButton"].exists ? app.buttons["TopTabsViewController.tabsButton"] : app.buttons["URLBarView.tabsButton"]
    }
}

extension XCUIElement {
    func tap(force force: Bool) {
        // There appears to be a bug with tapping elements sometimes, despite them being on-screen and tappable, due to hittable being false.
        // See: http://stackoverflow.com/a/33534187/1248491
        if hittable {
            tap()
        } else if force {
            coordinateWithNormalizedOffset(CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
