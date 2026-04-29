// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
class OpeningScreenTests: BaseTestCase {
    private var browserScreen: BrowserScreen!

    override func setUp() async throws {
        try await super.setUp()
        browserScreen = BrowserScreen(app: app)
    }

    func testLastOpenedTab() {
        // Open a web page
        browserScreen.navigateToURL(path(forTestPage: "test-mozilla-org.html"))
        waitUntilPageLoad()
        // Close the app from app switcher. Relaunch the app
        closeFromAppSwitcherAndRelaunch()
        // After re-launching the app, the last visited page is displayed
        browserScreen.assertAddressBarContains(value: "localhost")
        // Background and restore Firefox
        restartInBackground()
        // After re-launching the app, the last visited page is displayed
        browserScreen.assertAddressBarContains(value: "localhost")
    }
}
