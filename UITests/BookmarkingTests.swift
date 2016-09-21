/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class BookmarkingTests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    private func bookmark() {
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Add Bookmark")
    }

    private func unbookmark() {
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Remove Bookmark")
    }

    private func checkBookmarked() {
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().waitForViewWithAccessibilityLabel("Remove Bookmark")
        tester().tapViewWithAccessibilityLabel("Close Menu")
    }

    private func checkUnbookmarked() {
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().waitForViewWithAccessibilityLabel("Add Bookmark")
        tester().tapViewWithAccessibilityLabel("Close Menu")
    }

    /**
     * Tests basic page navigation with the URL bar.
     */
    func testBookmarkingUI() {
        // Load a page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Bookmark it using the bookmark button
        bookmark()
        checkBookmarked()

        // Load a different page in a new tab
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Tab")

        tester().tapViewWithAccessibilityIdentifier("url")
        let url2 = "\(webRoot)/numberedPage.html?page=2"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        // Check that the bookmark button is no longer selected
        checkUnbookmarked()

        // Now switch back to the original tab
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Page 1")
        checkBookmarked()

        // Check that it appears in the bookmarks home panel
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityIdentifier("HomePanels.Bookmarks")
        tester().waitForViewWithAccessibilityLabel("Page 1")

        // Tap to open it
        tester().tapViewWithAccessibilityLabel("Page 1")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Unbookmark it using the bookmark button
        unbookmark()
        checkUnbookmarked()

        // Check that it no longer appears in the bookmarks home panel
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityIdentifier("HomePanels.Bookmarks")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Page 1")
    }

    func testChangingDynamicFontOnBookmarks() {
        DynamicFontUtils.restoreDynamicFontSize(tester())

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityIdentifier("HomePanels.Bookmarks")

        let cell = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "SiteTable")

        let size = cell.textLabel?.font.pointSize

        DynamicFontUtils.bumpDynamicFontSize(tester())
        let bigSize = cell.textLabel?.font.pointSize

        DynamicFontUtils.lowerDynamicFontSize(tester())
        let smallSize = cell.textLabel?.font.pointSize

        XCTAssertGreaterThan(bigSize!, size!)
        XCTAssertGreaterThanOrEqual(size!, smallSize!)
    }

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
        tester().tapViewWithAccessibilityIdentifier("HomePanels.Bookmarks")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Page 1")
        // XXX: Searching for the table cell directly here can result in finding the wrong view.
        let cell = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "SiteTable")
        XCTAssertEqual(cell.textLabel!.text!, url1, "Cell shows url")

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    override func tearDown() {
        DynamicFontUtils.restoreDynamicFontSize(tester())
        BrowserUtils.clearHistoryItems(tester())
    }
}
