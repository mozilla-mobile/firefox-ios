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
        tester().tapViewWithAccessibilityIdentifier("url")
        var textView = tester().waitForViewWithAccessibilityLabel("Address and Search") as? UITextField
        XCTAssertTrue(textView!.text.isEmpty, "Text is empty")
        XCTAssertNotNil(textView!.placeholder, "Text view has a placeholder to show when its empty")

        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterText("\(url1)\n", intoViewWithAccessibilityLabel: "Address and Search")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapViewWithAccessibilityIdentifier("url")
        textView = tester().waitForViewWithAccessibilityLabel("Address and Search") as? UITextField
        XCTAssertEqual(textView!.text, url1, "Text is url")

        let url2 = "\(webRoot)/numberedPage.html?page=2"
        tester().clearTextFromAndThenEnterText("\(url2)\n", intoViewWithAccessibilityLabel: "Address and Search")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        tester().tapViewWithAccessibilityLabel("Back")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapViewWithAccessibilityLabel("Forward")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")
    }

    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
    }
}
