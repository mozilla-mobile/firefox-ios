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
        UIPasteboard.general.string = url
        app.textFields["url"].press(forDuration: 2.0)
        app.sheets.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        sleep(3) // TODO Otherwise we detect the body in the currently loaded document, before the new page has loaded

        let webView = app.webViews.element(boundBy: 0)
        let element = webView.otherElements[ariaLabel]
        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: element, handler: nil)

        waitForExpectations(timeout: 5.0) { (error) -> Void in
            if error != nil {
                XCTFail("Failed to detect element with ariaLabel=\(ariaLabel) on \(url): \(error)")
            }
        }
    }

    func loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        let LoadingTimeout: TimeInterval = 60
        let exists = NSPredicate(format: "exists = true")
        let loaded = NSPredicate(format: "value BEGINSWITH '100'")

        let app = XCUIApplication()

        UIPasteboard.general.string = url
        app.textFields["url"].press(forDuration: 2.0)
        app.sheets.element(boundBy: 0).buttons.element(boundBy: 0).tap()

        if waitForLoadToFinish {
            let progressIndicator = app.progressIndicators.element(boundBy: 0)
            expectation(for: exists, evaluatedWith: progressIndicator, handler: nil)
            expectation(for: loaded, evaluatedWith: progressIndicator, handler: nil)
            waitForExpectations(timeout: LoadingTimeout, handler: nil)
        }
    }
}
