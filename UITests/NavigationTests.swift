/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class NavigationTests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    /**
     * Tests basic page navigation with the URL bar.
     */
    func testNavigation() {
        tester().tapViewWithAccessibilityLabel("URL")
        let url1 = "\(webRoot)/?page=1"
        tester().clearTextFromAndThenEnterText("\(url1)\n", intoViewWithAccessibilityLabel: "Address and Search")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapViewWithAccessibilityLabel("URL")
        let url2 = "\(webRoot)/?page=2"
        tester().clearTextFromAndThenEnterText("\(url2)\n", intoViewWithAccessibilityLabel: "Address and Search")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        tester().tapViewWithAccessibilityLabel("Back")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapViewWithAccessibilityLabel("Forward")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")
    }
}
