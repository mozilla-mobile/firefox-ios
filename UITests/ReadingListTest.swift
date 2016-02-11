/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class ReadingListTests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        // We undo the localhost/127.0.0.1 switch in order to get 'localhost' in accessibility labels.
        webRoot = SimplePageServer.start()
                                  .stringByReplacingOccurrencesOfString("127.0.0.1", withString: "localhost", options: NSStringCompareOptions(), range: nil)
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

    func testChangingDyamicFontOnReadingList() {
        // Load a page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/readablePage.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

        // Add it to the reading list
        tester().tapViewWithAccessibilityLabel("Reader View")
        tester().tapViewWithAccessibilityLabel("Add to Reading List")

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")

        let cell = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "ReadingTable")

        let size = cell.textLabel?.font.pointSize

        DynamicFontUtils.bumpDynamicFontSize(tester())
        let bigSize = cell.textLabel?.font.pointSize

        DynamicFontUtils.lowerDynamicFontSize(tester())
        let smallSize = cell.textLabel?.font.pointSize

        XCTAssertGreaterThan(bigSize!, size!)
        XCTAssertGreaterThanOrEqual(size!, smallSize!)

        // Remove it from the reading list
        tester().tapViewWithAccessibilityLabel("Readable page, unread, localhost")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")
        tester().tapViewWithAccessibilityLabel("Remove from Reading List")
    }

    func testReadingListAutoMarkAsRead() {
        // Load a page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/readablePage.html"
        tester().clearTextFromAndThenEnterText("\(url1)\n", intoViewWithAccessibilityLabel: "Address and Search")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

        // Add it to the reading list
        tester().tapViewWithAccessibilityLabel("Reader View")
        tester().tapViewWithAccessibilityLabel("Add to Reading List")

        // Check that it appears in the reading list home panel and make sure it marked as unread
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().waitForViewWithAccessibilityLabel("Readable page, unread, localhost")

        // Tap to open it
        tester().tapViewWithAccessibilityLabel("Readable page, unread, localhost")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")

        // Go back to the reading list panel
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")

        // Make sure the article is marked as read
        let labelString = NSMutableAttributedString(string: "Readable page, read, localhost")
        labelString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(float: 0.7), range: NSMakeRange(0, labelString.length))
        tester().waitForViewWithAttributedAccessibilityLabel(labelString)
    }

    override func tearDown() {
        DynamicFontUtils.restoreDynamicFontSize(tester())
        BrowserUtils.clearHistoryItems(tester(), numberOfTests: 5)
    }
}
