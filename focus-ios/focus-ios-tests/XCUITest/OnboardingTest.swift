/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class OnboardingTest: BaseTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = []
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
        app.terminate()
    }

    // Smoketest
    // https://mozilla.testrail.io/index.php?/cases/view/394959
    func testPressingDots() throws {
        let pageIndicatorButton = app.pageIndicators.firstMatch
        XCTAssertEqual(pageIndicatorButton.value as? String, "page 1 of 2")

        waitForExistence(app.staticTexts["Welcome to Firefox Focus!"])
        waitForExistence(app.images["icon_background"])
        XCTAssert(app.buttons["Get Started"].isEnabled)
        XCTAssert(app.buttons["icon_close"].isEnabled)
        pageIndicatorButton.tap()

        XCTAssertEqual(pageIndicatorButton.value as? String, "page 2 of 2")
        waitForExistence(app.staticTexts["Focus isn’t like other browsers"])
        waitForExistence(app.images["icon_hugging_focus"])
        waitForEnable(app.buttons["Set as Default Browser"])
        waitForEnable(app.buttons["Skip"])
        waitForEnable(app.buttons["icon_close"])
        pageIndicatorButton.tap()

        XCTAssertEqual(pageIndicatorButton.value as? String, "page 1 of 2")
        waitForExistence(app.staticTexts["Welcome to Firefox Focus!"])
        pageIndicatorButton.tap()

        XCTAssertEqual(pageIndicatorButton.value as? String, "page 2 of 2")
        waitForExistence(app.staticTexts["Focus isn’t like other browsers"])
    }
}
