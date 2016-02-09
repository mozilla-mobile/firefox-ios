/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client

class BrowserTests: KIFTestCase {

    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testDisplaySharesheetWhileJSPromptOccurs() {
        let url = "\(webRoot)/JSPrompt.html"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("JS Prompt")
        // Show share sheet and wait for the JS prompt to fire
        tester().tapViewWithAccessibilityLabel("Share")
        tester().waitForTimeInterval(5)
        tester().tapViewWithAccessibilityLabel("Cancel")

        // Check to see if the JS Prompt is dequeued and showing
        tester().waitForViewWithAccessibilityLabel("OK")
        tester().tapViewWithAccessibilityLabel("OK")

        BrowserUtils.resetToAboutHome(tester())
    }
}