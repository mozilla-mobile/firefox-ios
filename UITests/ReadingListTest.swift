/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class ReadingListTests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        // We undo the localhost/127.0.0.1 switch in order to get 'localhost' in accessibility labels.
        webRoot = SimplePageServer.start()
            .replacingOccurrences(of: "127.0.0.1", with: "localhost", options: NSString.CompareOptions(), range: nil)
        BrowserUtils.dismissFirstRunUI(tester())
    }

    /**
     * Tests opening reader mode pages from the urlbar and reading list.
     */
    func testReadingList() {
        // Load a page
        tester().tapView(withAccessibilityIdentifier: "url")
        let url1 = "\(webRoot)/readablePage.html"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

        // Add it to the reading list
        tester().tapView(withAccessibilityLabel: "Reader View")
        tester().tapView(withAccessibilityLabel: "Add to Reading List")

        // Open a new page
        tester().tapView(withAccessibilityIdentifier: "url")
        let url2 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Check that it appears in the reading list home panel
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")

        // Tap to open it
        tester().tapView(withAccessibilityLabel: "Readable page, unread, localhost")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")

        // Remove it from the reading list
        tester().tapView(withAccessibilityLabel: "Remove from Reading List")

        // Check that it no longer appears in the reading list home panel
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Readable page, unread, localhost")
        tester().tapView(withAccessibilityLabel: "Cancel")
    }

    /*
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
 */

    func testReadingListAutoMarkAsRead() {
        // Load a page
        tester().tapView(withAccessibilityIdentifier: "url")
        let url1 = "\(webRoot)/readablePage.html"
        //tester().clearTextFromAndThenEnterText("\(url1)\n", intoViewWithAccessibilityLabel: "Address and Search")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

        // Add it to the reading list
        tester().tapView(withAccessibilityLabel: "Reader View")
        tester().tapView(withAccessibilityLabel: "Add to Reading List")

        // Check that it appears in the reading list home panel and make sure it marked as unread
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")
        tester().waitForView(withAccessibilityLabel: "Readable page, unread, localhost")

        // Tap to open it
        tester().tapView(withAccessibilityLabel: "Readable page, unread, localhost")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")

        // Go back to the reading list panel
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")

        // Make sure the article is marked as read
        let labelString = NSMutableAttributedString(string: "Readable page, read, localhost")
        labelString.addAttribute(UIAccessibilitySpeechAttributePitch, value: NSNumber(value: 0.7 as Float), range: NSMakeRange(0, labelString.length))
        tester().waitForViewWithAttributedAccessibilityLabel(labelString)
    }

    override func tearDown() {
        //DynamicFontUtils.restoreDynamicFontSize(tester())
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
}
