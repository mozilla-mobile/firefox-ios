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
        tester().tapViewWithAccessibilityLabel("Bookmark")
        let bookmarkButton = tester().waitForViewWithAccessibilityLabel("Bookmark") as! UIButton
        XCTAssertTrue(bookmarkButton.selected, "Bookmark button is marked selected")

        // Load a different page in a new tab
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Add Tab")

        tester().tapViewWithAccessibilityIdentifier("url")
        let url2 = "\(webRoot)/numberedPage.html?page=2"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        // Check that the bookmark button is no longer selected
        XCTAssertFalse(bookmarkButton.selected, "Bookmark button is not marked selected")

        // Now switch back to the original tab
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Page 1")
        XCTAssertTrue(bookmarkButton.selected, "Bookmark button is marked selected")

        // Check that it appears in the bookmarks home panel
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Bookmarks")

        // Tap to open it
        tester().tapViewWithAccessibilityLabel("Page 1")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Unbookmark it using the bookmark button
        tester().tapViewWithAccessibilityLabel("Bookmark")
        XCTAssertFalse(bookmarkButton.selected, "Bookmark button is not selected")

        // Check that it no longer appears in the bookmarks home panel
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Bookmarks")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Page 1")

        // The "default" bookmarks (suggested sites) should now show here.
        tester().waitForViewWithAccessibilityLabel("The Mozilla Project")
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func testBookmarkNoTitle() {
        // Load a page with no title
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/noTitle.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("This page has no title")

        // Bookmark it using the bookmark button
        tester().tapViewWithAccessibilityLabel("Bookmark")
        let bookmarkButton = tester().waitForViewWithAccessibilityLabel("Bookmark") as! UIButton
        XCTAssertTrue(bookmarkButton.selected, "Bookmark button is marked selected")

        // Check that its row in the bookmarks panel has a url instead of a title
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Bookmarks")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Page 1")
        // XXX: Searching for the table cell directly here can result in finding the wrong view.
        let cell = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "SiteTable")
        XCTAssertEqual(cell.textLabel!.text!, url1, "Cell shows url")

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func testChangeBookmarkTitle() {
        // Load a page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        
        // Bookmark it using the bookmark button
        tester().tapViewWithAccessibilityLabel("Bookmark")
        let bookmarkButton = tester().waitForViewWithAccessibilityLabel("Bookmark") as! UIButton
        XCTAssertTrue(bookmarkButton.selected, "Bookmark button is marked selected")
        
        // Check that it appears in the bookmarks home panel
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Bookmarks")
        
        // Check whether swiping on the bookmark cell shows the edit button
        let cell = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "SiteTable")
        tester().swipeViewWithAccessibilityLabel("Page 1", inDirection: .Left)
        XCTAssertNotNil(UIApplication.sharedApplication().keyWindow!.accessibilityElementWithLabel("Edit"), "Cell shows edit action button")
        
        // Check whether tapping the button opens a popup
        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForViewWithAccessibilityLabel("Edit bookmark title") // wait until popup is animated on screen
        
        // Check whether bookmark title keeps unchanged if tapping cancel
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Edit bookmark title") // wait until popup has dissapeared
        XCTAssertEqual(cell.textLabel!.text!, "Page 1", "Cell shows unchanged bookmark title")
        
        // Check whether setting a new title in the AlertView changes the title of the bookmark in the cell
        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForViewWithAccessibilityLabel("Edit bookmark title") // wait until popup is animated on screen
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("Test\n")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Edit bookmark title") // wait until popup has disappeared
        let reloadedCell = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "SiteTable")
        
        XCTAssertEqual(reloadedCell.textLabel!.text!, "Test", "Cell shows new bookmark title")
        
        // Check whether swiping on the bookmark cell shows the edit button
        tester().swipeViewWithAccessibilityLabel("Test", inDirection: .Left)
        XCTAssertNotNil(UIApplication.sharedApplication().keyWindow!.accessibilityElementWithLabel("Edit"), "Cell shows edit action button")
        
        // Check whether tapping the button opens a popup
        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForViewWithAccessibilityLabel("Edit bookmark title") // wait until popup is animated on screen
        
        // Check whether button is disabled for empty string
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("")
        tester().waitForAccessibilityElement(nil, view: nil, withLabel: "OK", value: nil, traits: UIAccessibilityTraitNotEnabled, tappable: false)
        
        // Check whether button get re-enabled after replacing invalid string with valid string
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("Test")
        tester().waitForAccessibilityElement(nil, view: nil, withLabel: "OK", value: nil, traits: UIAccessibilityTraitButton, tappable: true)
        
        // Check whether button is disabled for whitespace-only string
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("   ")
        tester().waitForAccessibilityElement(nil, view: nil, withLabel: "OK", value: nil, traits: UIAccessibilityTraitNotEnabled, tappable: false)
        tester().tapViewWithAccessibilityLabel("Cancel")
    }
    
    override func tearDown() {
        BrowserUtils.clearHistoryItems(tester())
    }
}
