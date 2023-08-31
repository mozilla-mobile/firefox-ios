// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class UrlBarTests: BaseTestCase {
    // https://testrail.stage.mozaws.net/index.php?/cases/view/2189026
    func testNewTabUrlBar() {
        // Visit any website and select the URL bar
        navigator.openURL("http://localhost:\(serverPort)/test-fixture/find-in-page-test.html")
        waitUntilPageLoad()
        app.textFields["url"].tap()
        // The keyboard is brought up.
        let addressBar = app.textFields["address"]
        XCTAssertTrue(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? false)
        // Scroll on the page
        app.swipeUp()
        // The keyboard is dismissed
        XCTAssertFalse(addressBar.value(forKey: "hasKeyboardFocus") as? Bool ?? true)
        // Select the tab tray and add a new tab
        navigator.goto(TabTray)
        navigator.performAction(Action.OpenNewTabFromTabTray)
        // The URL bar is empty on the new tab
        XCTAssertEqual(app.textFields["url"].value as! String, "Search or enter address")
    }
}
