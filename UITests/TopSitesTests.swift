/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class TopSitesTests: KIFTestCase {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    /**
    * Tests for removing a site from top sites
    */
    func testBasicUI() {
        // Load a page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Now load another
        tester().tapViewWithAccessibilityIdentifier("url")
        let url2 = "\(webRoot)/numberedPage.html?page=2"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        // Open top sites and tap the entry for Page 1
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Top sites")
        tester().tapViewWithAccessibilityLabel("Page 1")

        // Verify that Page 1 loads
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
    }

    /**
    * Tests for removing a site from top sites
    */
    func testRemovingSite() {
        // Load a page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Open top sites
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Top sites")

        // Verify the row exists and that the Remove Page button is hidden
        let row = tester().waitForViewWithAccessibilityLabel("Page 1")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Remove page")

        // Long press the row and click the remove button
        row.longPressAtPoint(CGPoint(x: 0,y: 0), duration: 1)
        tester().tapViewWithAccessibilityLabel("Remove page")

        // Close editing mode
        tester().tapViewWithAccessibilityLabel("Done")

        // Close top sites
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
    }
}
