/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class RequestDesktopTest: BaseTestCase {
    // Smoketest
    // Disabled due to issue #2782
    func testActivityMenuRequestDesktopItem() throws {
        throw XCTSkip("Due to bug 2782")
        let urlBarTextField = app.textFields["URLBar.urlText"]

        // Wait for existence rather than hittable because the textfield is technically disabled
        loadWebPage("facebook.com")

        waitForWebPageLoad()
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()

        if iPad() {
            waitForExistence(app.tables.cells["request_mobile_site_activity"])
            app.tables.cells["request_mobile_site_activity"].tap()
        } else {
            waitForExistence(app.tables.cells["request_desktop_site_activity"])
            app.tables.cells["request_desktop_site_activity"].tap()
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
