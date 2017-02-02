/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client

class BrowserTests: KIFTestCase {

    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    override func tearDown() {
        super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }

    func testDisplaySharesheetWhileJSPromptOccurs() {
        let url = "\(webRoot)/JSPrompt.html"
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("JS Prompt")
        // Show share sheet and wait for the JS prompt to fire
        tester().tapView(withAccessibilityLabel: "Share")
        tester().wait(forTimeInterval: 5)
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: "Cancel")
            tester().tapView(withAccessibilityLabel: "Cancel")
        } catch {
            tester().tapView(withAccessibilityLabel: "dismiss popup")
        }
        
        // Check to see if the JS Prompt is dequeued and showing
        tester().waitForView(withAccessibilityLabel: "OK")
        tester().tapView(withAccessibilityLabel: "OK")
    }
}
