/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class SettingsTests: KIFTestCase {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testHelpOpensSUMOInTab() {
        MenuUtils.openSettings(tester())
        tester().tapViewWithAccessibilityLabel("Help")
        tester().waitForAnimationsToFinish()
        tester().waitForViewWithAccessibilityLabel("https://support.mozilla.org/en-US/products/ios")
        BrowserUtils.resetToAboutHome(tester())
    }
}
