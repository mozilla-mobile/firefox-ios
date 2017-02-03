/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class SettingsTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    override func tearDown() {
        super.tearDown()
    }

    func testHelpOpensSUMOInTab() {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Help")
        tester().waitForAnimationsToFinish()
        tester().waitForView(withAccessibilityLabel: "https://support.mozilla.org/en-US/products/ios")
        BrowserUtils.resetToAboutHome(tester())
    }
}
