/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class BaseTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        app.terminate()
        restart(app, args: [LaunchArguments.ClearProfile, LaunchArguments.SkipIntro, LaunchArguments.SkipWhatsNew])
    }

    override func tearDown() {
        XCUIApplication().terminate()
        super.tearDown()
    }

    func restart(_ app: XCUIApplication, args: [String] = []) {
        XCUIDevice.shared().press(.home)
        var launchArguments = [LaunchArguments.Test]
        args.forEach { arg in
            launchArguments.append(arg)
        }
        app.launchArguments = launchArguments
        app.activate()
    }
    
    //If it is a first run, first run window should be gone
    func dismissFirstRunUI() {
        let firstRunUI = XCUIApplication().scrollViews["IntroViewController.scrollView"]
        
        if firstRunUI.exists {
            firstRunUI.swipeLeft()
            XCUIApplication().buttons["Start Browsing"].tap()
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
        //TODO: Failing with expectation
//        if waitForLoadToFinish {
//            let finishLoadingTimeout: TimeInterval = 30
//            let progressIndicator = app.progressIndicators.element(boundBy: 0)
//            expectation(for: NSPredicate(format: "exists = true"), evaluatedWith: progressIndicator, handler: nil)
//            expectation(for: NSPredicate(format: "value BEGINSWITH '0'"), evaluatedWith: progressIndicator, handler: nil)
//            
//            waitForExpectations(timeout: finishLoadingTimeout, handler: nil)
//        }
    }
    
    func iPad() -> Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        return false
    }
}

extension BaseTestCase {
    func tabTrayButton(forApp app: XCUIApplication) -> XCUIElement {
        return app.buttons["TopTabsViewController.tabsButton"].exists ? app.buttons["TopTabsViewController.tabsButton"] : app.buttons["TabToolbar.tabsButton"]
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
