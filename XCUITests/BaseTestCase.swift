//
//  BaseTestCase.swift
//  Client
//
//  Created by Farhan Patel on 7/14/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest

class BaseTestCase: XCTestCase {
    
    private var pageLoaded: XCTestExpectation?

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        restart(app, reset: true)
    }

    override func tearDown() {
        super.tearDown()
    }

    func restart(app: XCUIApplication, reset: Bool) {
        app.terminate()
        app.launchArguments.append("FIREFOX_TESTS")
        if reset {
            app.launchArguments.append("RESET_FIREFOX")
        }
        app.launch()
        sleep(1)
    }

    func loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        let exists = NSPredicate(format: "exists == true")
        let doesNotExist = NSPredicate(format: "exists == false")

        let app = XCUIApplication()
        let progressIndicator = app.descendantsMatchingType(.Any)["Loaded web page"]
        let webPageWasNotAlreadyLoading = progressIndicator.exists

        UIPasteboard.generalPasteboard().string = url
        app.textFields["url"].pressForDuration(2.0)
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()

        if waitForLoadToFinish {
            let startLoadingTimeout: NSTimeInterval = 5
            let finishLoadingTimeout: NSTimeInterval = 10

            if webPageWasNotAlreadyLoading {
                expectationForPredicate(doesNotExist, evaluatedWithObject: progressIndicator, handler: nil)
                waitForExpectationsWithTimeout(startLoadingTimeout, handler: nil) // It takes a short time for a page to begin loading after the navigation action has been made
            }
            expectationForPredicate(exists, evaluatedWithObject: progressIndicator, handler: nil)
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