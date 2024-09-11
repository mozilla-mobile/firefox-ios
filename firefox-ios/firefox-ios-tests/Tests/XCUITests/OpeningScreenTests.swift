// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
class OpeningScreenTests: BaseTestCase {
    // https://mozilla.testrail.io/index.php?/cases/view/2307039
    func testLastOpenedTab() {
        // Open a web page
        navigator.openURL(path(forTestPage: "test-mozilla-org.html"), waitForLoading: true)
        waitUntilPageLoad()
        // Close the app from app switcher. Relaunch the app
        closeFromAppSwitcherAndRelaunch()
        // After re-launching the app, the last visited page is displayed
        mozWaitForValueContains(app.textFields["url"], value: "test-mozilla-org")
        // Background and restore Firefox
        restartInBackground()
        // After re-launching the app, the last visited page is displayed
        mozWaitForValueContains(app.textFields["url"], value: "test-mozilla-org")
    }
}
