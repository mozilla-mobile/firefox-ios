//
//  BaseTestCase.swift
//  Client
//
//  Created by Farhan Patel on 7/14/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import XCTest


class BaseTestCase: XCTestCase {

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
        let LoadingTimeout: NSTimeInterval = 20
        let exists = NSPredicate(format: "exists = true")
        let loaded = NSPredicate(format: "value BEGINSWITH '100'")

        let app = XCUIApplication()

        UIPasteboard.generalPasteboard().string = url
        app.textFields["url"].pressForDuration(2.0)
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()

        if waitForLoadToFinish {
            let progressIndicator = app.progressIndicators.elementBoundByIndex(0)
            expectationForPredicate(exists, evaluatedWithObject: progressIndicator, handler: nil)
            expectationForPredicate(loaded, evaluatedWithObject: progressIndicator, handler: nil)
            waitForExpectationsWithTimeout(LoadingTimeout, handler: nil)
        }
    }

}