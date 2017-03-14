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
        XCUIApplication().terminate()
        super.tearDown()
    }

    func restart(_ app: XCUIApplication) {
        app.terminate()
        app.launchArguments.append(LaunchArguments.Test)
        app.launchArguments.append(LaunchArguments.ClearProfile)
        app.launch()
        sleep(1)
    }
    
    //If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().buttons["Start Browsing"]
        
        if firstRunUI.exists {
            firstRunUI.tap()
        }
    }
    
    func waitforExistence(_ element: XCUIElement) {
        let exists = NSPredicate(format: "exists == true")
        
        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    func waitforNoExistence(_ element: XCUIElement) {
        let exists = NSPredicate(format: "exists != true")
        
        expectation(for: exists, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20, handler: nil)
    }
    
    func waitForValueContains(_ element: XCUIElement, value: String) {
        let predicateText = "value CONTAINS " + "'" + value + "'"
        let valueCheck = NSPredicate(format: predicateText)
        
        expectation(for: valueCheck, evaluatedWith: element, handler: nil)
        waitForExpectations(timeout: 20, handler: nil)
    }

    func loadWebPage(_ url: String, waitForLoadToFinish: Bool = true) {
        let app = XCUIApplication()
        UIPasteboard.general.string = url
        app.textFields["url"].press(forDuration: 2.0)
        app.sheets.element(boundBy: 0).buttons.element(boundBy: 0).tap()

        if waitForLoadToFinish {
            let finishLoadingTimeout: TimeInterval = 30
            let progressIndicator = app.progressIndicators.element(boundBy: 0)
            expectation(for: NSPredicate(format: "exists = false"), evaluatedWith: progressIndicator, handler: nil)
            waitForExpectations(timeout: finishLoadingTimeout, handler: nil)
        }
    }

}

extension BaseTestCase {
    func tabTrayButton(forApp app: XCUIApplication) -> XCUIElement {
        return app.buttons["TopTabsViewController.tabsButton"].exists ? app.buttons["TopTabsViewController.tabsButton"] : app.buttons["URLBarView.tabsButton"]
    }
}

extension XCUIElement {
    func tap(force: Bool) {
        // There appears to be a bug with tapping elements sometimes, despite them being on-screen and tappable, due to hittable being false.
        // See: http://stackoverflow.com/a/33534187/1248491
        if isHittable {
            tap()
        } else if force {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
