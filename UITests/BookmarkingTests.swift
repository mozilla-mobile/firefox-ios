/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class BookmarkingTests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }
    
    fileprivate func bookmark() {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Add Bookmark")
    }

    fileprivate func unbookmark() {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Remove Bookmark")
    }

    fileprivate func checkBookmarked() {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().waitForView(withAccessibilityLabel: "Remove Bookmark")
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: "Close Menu")
            tester().tapView(withAccessibilityLabel: "Close Menu")
        } catch {
            tester().tapView(withAccessibilityLabel: "dismiss popup")
        }
    }

    fileprivate func checkUnbookmarked() {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().waitForView(withAccessibilityLabel: "Add Bookmark")
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: "Close Menu")
            tester().tapView(withAccessibilityLabel: "Close Menu")
        } catch {
            tester().tapView(withAccessibilityLabel: "dismiss popup")
        }
    }

    /**
     * Tests basic page navigation with the URL bar.
     */
    func testBookmarkingUI() {
        // Load a page
        tester().tapView(withAccessibilityIdentifier: "url")
        let url1 = "www.google.com"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url1)\n")
        //tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Bookmark it using the bookmark button
        bookmark()
        checkBookmarked()

        // Load a different page in a new tab
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Tab")

        tester().tapView(withAccessibilityIdentifier: "url")
        let url2 = "www.mozilla.org"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url2)\n")
       // tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        // Check that the bookmark button is no longer selected
        checkUnbookmarked()

        // Now switch back to the original tab
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Google")
        checkBookmarked()

        // Check that it appears in the bookmarks home panel
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Bookmarks")
        tester().waitForView(withAccessibilityLabel: "Google")

        // Tap to open it
        tester().tapView(withAccessibilityLabel: "Google")
        //tester().waitForWebViewElementWithAccessibilityLabel("Google")

        // Unbookmark it using the bookmark button
        unbookmark()
        checkUnbookmarked()

        // Check that it no longer appears in the bookmarks home panel
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Bookmarks")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "google")
    }

    // Disabled since font changing hack is no longer working for ios 10
    /*
    func testChangingDynamicFontOnBookmarks() {
        DynamicFontUtils.restoreDynamicFontSize(tester())

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Bookmarks")

        let cell = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "SiteTable")

        let size = cell.textLabel?.font.pointSize

        DynamicFontUtils.bumpDynamicFontSize(tester())
        let bigSize = cell.textLabel?.font.pointSize

        DynamicFontUtils.lowerDynamicFontSize(tester())
        let smallSize = cell.textLabel?.font.pointSize

        XCTAssertGreaterThan(bigSize!, size!)
        XCTAssertGreaterThanOrEqual(size!, smallSize!)
    }
     */

    // Disabled since local pages are no longer bookmarkable
    /*
    func testBookmarkNoTitle() {
        // Load a page with no title
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        // Bookmark it using the bookmark button
        bookmark()
        checkBookmarked()

        // Check that its row in the bookmarks panel has a url instead of a title
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Bookmarks")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Page 1")
        // XXX: Searching for the table cell directly here can result in finding the wrong view.
        let cell = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "SiteTable")
        XCTAssertEqual(cell.textLabel!.text!, url1, "Cell shows url")

        tester().tapViewWithAccessibilityLabel("Cancel")
    }
     */
    override func tearDown() {
         super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
}
