/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class QuickAddAutocompleteURLTest: BaseTestCase {
    func testURLContextMenu() {

        let urlBarTextField = app.textFields["URLBar.urlText"]
        loadWebPage("reddit.com")

        urlBarTextField.press(forDuration: 1.0)
        waitForHittable(app.cells["Add Custom URL"])
        app.cells["Add Custom URL"].tap()

        waitForHittable(app.textFields["URLBar.urlText"])
        urlBarTextField.tap()
        urlBarTextField.typeText("reddit.c\n")

        guard let text = urlBarTextField.value as? String else {
            XCTFail()
            return
        }

        waitForValueContains(app.textFields["URLBar.urlText"], value: "reddit.com")
    }
}
