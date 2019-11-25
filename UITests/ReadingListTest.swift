/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import EarlGrey
import WebKit

class ReadingListTests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        // We undo the localhost/127.0.0.1 switch in order to get 'localhost' in accessibility labels.
        webRoot = SimplePageServer.start()
            .replacingOccurrences(of: "127.0.0.1", with: "localhost")
        BrowserUtils.configEarlGrey()
        BrowserUtils.dismissFirstRunUI()
    }

    func waitForReadingList() {
        let readingList = GREYCondition(name: "wait until Reading List Add btn appears", block: {
            var errorOrNil: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel("Add to Reading List"),
                                              grey_sufficientlyVisible()])
            EarlGrey.selectElement(with: matcher)
                .assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil == nil
            return success
        }).wait(withTimeout: 20)

        GREYAssertTrue(readingList, reason: "Can't be added to Reading List")
    }

    func waitForEmptyReadingList() {
        let readable = GREYCondition(name: "Check readable list is empty", block: {
            var error: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel("Save pages to your Reading List by tapping the book plus icon in the Reader View controls."),
                                              grey_sufficientlyVisible()])
            EarlGrey.selectElement(with: matcher)
                .assert(grey_notNil(), error: &error)

            return error == nil
        }).wait(withTimeout: 10)
        GREYAssertTrue(readable, reason: "Read list should not appear")
    }

    /**
     * Tests opening reader mode pages from the urlbar and reading list.
     */
    func testReadingList() {
        // Load a page
        let url1 = "\(webRoot!)/readablePage.html"
        BrowserUtils.enterUrlAddressBar(typeUrl: url1)
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

        // Add it to the reading list
        EarlGrey.selectElement(with: grey_accessibilityLabel("Reader View"))
            .perform(grey_tap())
        waitForReadingList()
        EarlGrey.selectElement(with: grey_accessibilityLabel("Add to Reading List"))
            .perform(grey_tap())

        // Open a new page
        let url2 = "\(webRoot!)/numberedPage.html?page=1"
        BrowserUtils.enterUrlAddressBar(typeUrl: url2)
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Check that it appears in the reading list home panel
        BrowserUtils.openLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: "LibraryPanels.ReadingList")

        // Tap to open it
        EarlGrey.selectElement(with: grey_accessibilityLabel("localhost"))
            .perform(grey_tap())
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")

        // Remove it from the reading list
        EarlGrey.selectElement(with: grey_accessibilityLabel("Remove from Reading List"))
            .perform(grey_tap())

        // Check that it no longer appears in the reading list home panel
        BrowserUtils.openLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: "LibraryPanels.Bookmarks")
        tester().tapView(withAccessibilityIdentifier: "LibraryPanels.ReadingList")
        waitForEmptyReadingList()

        // Close the menu
        tester().tapView(withAccessibilityIdentifier: "LibraryPanels.History")
        BrowserUtils.closeLibraryMenu(tester())
    }

    func testReadingListAutoMarkAsRead() {
        // Load a page
        let url1 = "\(webRoot!)/readablePage.html"
        BrowserUtils.enterUrlAddressBar(typeUrl: url1)
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

        // Add it to the reading list
        EarlGrey.selectElement(with: grey_accessibilityLabel("Reader View"))
            .perform(grey_tap())
        waitForReadingList()
        EarlGrey.selectElement(with: grey_accessibilityLabel("Add to Reading List"))
            .perform(grey_tap())

        // Check that it appears in the reading list home panel and make sure it marked as unread
        BrowserUtils.openLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: "LibraryPanels.ReadingList")

        tester().waitForView(withAccessibilityLabel: "Readable page, unread, localhost")
        // Select to Read
        EarlGrey.selectElement(with: grey_accessibilityLabel("localhost"))
            .perform(grey_tap())
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")

        // Go back to the reading list panel
        BrowserUtils.openLibraryMenu(tester())

        // Make sure the article is marked as read
        EarlGrey.selectElement(with: grey_accessibilityLabel("Readable page"))
            .inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")!))
            .assert(grey_notNil())
        tester().waitForView(withAccessibilityLabel: "Readable page, read, localhost")
        EarlGrey.selectElement(with: grey_accessibilityLabel("localhost"))
            .assert(grey_notNil())

        // Remove the list entry
        // Workaround for iPad, the swipe gesture is not controlled and the Remove button
        // is kept behing the Mark as read and so the test fails
        if BrowserUtils.iPad() {
            EarlGrey.selectElement(with: grey_accessibilityLabel("Readable page"))
                .inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")!))
                .perform(grey_longPress())
            tester().longPressView(withAccessibilityIdentifier: "action_remove", duration: 1)
        } else {
            EarlGrey.selectElement(with: grey_accessibilityLabel("Readable page"))
                .inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")!))
                .perform(grey_swipeSlowInDirectionWithStartPoint(GREYDirection.left, 0.1, 0.1))
            tester().waitForAnimationsToFinish()
            EarlGrey.selectElement(with: grey_accessibilityLabel("Remove"))
                .perform(grey_tap())
        }

        // check the entry no longer exist
        waitForEmptyReadingList()

        // Close Reading (and so Library) panel
        tester().tapView(withAccessibilityIdentifier: "LibraryPanels.History")
        BrowserUtils.closeLibraryMenu(tester())
    }

    override func tearDown() {
        BrowserUtils.resetToAboutHome()
        BrowserUtils.clearPrivateData()
        super.tearDown()
    }
}
