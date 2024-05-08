/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class RequestDesktopTest: BaseTestCase {
    // Smoketest
    // Disabled due to issue #2782
    func testActivityMenuRequestDesktopItem() {
        let urlBarTextField = app.textFields["URLBar.urlText"]

        // Wait for existence rather than hittable because the textfield is technically disabled
        loadWebPage("facebook.com")

        waitForWebPageLoad()
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()

        if iPad() {
            waitForExistence(app.collectionViews.buttons["Request Mobile Site"])
            app.collectionViews.buttons["Request Mobile Site"].tap()
        } else {
            print(app.debugDescription)
            waitForExistence(app.collectionViews.buttons["Request Desktop Site"])
            app.collectionViews.buttons["Request Desktop Site"].tap()
        }

        waitForWebPageLoad()

        guard let text = urlBarTextField.value as? String else {
            XCTFail()
            return
        }

        if text.contains("m.facebook") {
            if !iPad() {
                XCTFail()
            }
        }
    }
}
