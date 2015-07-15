/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class ReadingListTests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    /**
     * Tests opening reader mode pages from the urlbar and reading list.
     */
    func testReadingList() {
        // Load a page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/readablePage.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

        // Add it to the reading list
        tester().tapViewWithAccessibilityLabel("Reader View")
        tester().tapViewWithAccessibilityLabel("Add to Reading List")

        // Open a new page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url2 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Check that it appears in the reading list home panel
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")

        // Tap to open it
        tester().tapViewWithAccessibilityLabel("Readable page, unread, localhost")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")

        // Remove it from the reading list
        tester().tapViewWithAccessibilityLabel("Remove from Reading List")

        // Check that it no longer appears in the reading list home panel
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Readable page, unread, localhost")
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
    }
}
