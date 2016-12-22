/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nBaseSnapshotTests: XCTestCase {
    var skipIntro: Bool {
        return true
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments = [LaunchArguments.Test, LaunchArguments.ClearProfile]
        if skipIntro {
            app.launchArguments.append(LaunchArguments.SkipIntro)
        }
        app.launch()
    }

    func loadWebPage(url: String, waitForOtherElementWithAriaLabel ariaLabel: String) {
        let app = XCUIApplication()
        UIPasteboard.generalPasteboard().string = url
        app.textFields["url"].pressForDuration(2.0)
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()

        sleep(3) // TODO Otherwise we detect the body in the currently loaded document, before the new page has loaded

        let webView = app.webViews.elementBoundByIndex(0)
        let element = webView.otherElements[ariaLabel]
        expectationForPredicate(NSPredicate(format: "exists == 1"), evaluatedWithObject: element, handler: nil)

        waitForExpectationsWithTimeout(5.0) { (error) -> Void in
            if error != nil {
                XCTFail("Failed to detect element with ariaLabel=\(ariaLabel) on \(url): \(error)")
            }
        }
    }

    func loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        let LoadingTimeout: NSTimeInterval = 60
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
