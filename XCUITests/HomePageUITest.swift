/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class HomePageUITest: BaseTestCase {
    func testSetInternalURLAsHomepage() {
        loadWebPage("http://en.m.wikipedia.org/wiki/Main_Page")
        app.buttons["Reader View"].tap()
        navigator.goto(PageOptionsMenu)
        app.cells["Set as Homepage"].tap()
        app.buttons["Set Homepage"].tap()
        navigator.nowAt(BrowserTab)
        XCTAssertTrue(app.alerts.count == 0)
    }
}
