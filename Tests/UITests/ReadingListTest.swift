// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import WebKit

class ReadingListTests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        // We undo the localhost/127.0.0.1 switch in order to get 'localhost' in accessibility labels.
        webRoot = SimplePageServer.start()
            .replacingOccurrences(of: "127.0.0.1", with: "localhost")
        BrowserUtils.dismissFirstRunUI(tester())
    }

    func waitForReadingList() {
         tester().waitForView(withAccessibilityLabel: "Add to Reading List")
    }

    func waitForEmptyReadingList() {
        tester().waitForView(withAccessibilityLabel: "Save pages to your Reading List by tapping the book plus icon in the Reader View controls.")
    }

    /**
     * Tests opening reader mode pages from the urlbar and reading list.
     */
    func testReadingList() {
        // Load a page
        let url1 = "\(webRoot!)/readablePage.html"
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url1)
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

        // Add it to the reading list
        tester().tapView(withAccessibilityLabel: "Reader View")
        waitForReadingList()
        tester().tapView(withAccessibilityLabel: "Add to Reading List")

        // Open a new page
        let url2 = "\(webRoot!)/numberedPage.html?page=1"
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url2)
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Check that it appears in the reading list home panel
        BrowserUtils.openLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: ImageIdentifiers.readingList)

        // Tap to open it
        let firstIndexPath = IndexPath(row: 0, section: 0)
        tester().tapRow(at: firstIndexPath, inTableViewWithAccessibilityIdentifier: "ReadingTable")

        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")

        // Remove it from the reading list
        tester().tapView(withAccessibilityLabel: "Remove from Reading List")

        // Check that it no longer appears in the reading list home panel
        BrowserUtils.openLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: ImageIdentifiers.readingList)
        waitForEmptyReadingList()

        // Close the menu
        BrowserUtils.closeLibraryMenu(tester())
    }

    func testReadingListAutoMarkAsRead() {
        // Load a page
        let url1 = "\(webRoot!)/readablePage.html"
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url1)
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

        // Add it to the reading list
        tester().tapView(withAccessibilityLabel: "Reader View")
        waitForReadingList()
        tester().tapView(withAccessibilityLabel: "Add to Reading List")

        // Check that it appears in the reading list home panel and make sure it marked as unread
        BrowserUtils.openLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: ImageIdentifiers.readingList)

        tester().waitForView(withAccessibilityLabel: "Readable page, unread, localhost")
        // Select to Read
        let firstIndexPath = IndexPath(row: 0, section: 0)
        tester().tapRow(at: firstIndexPath, inTableViewWithAccessibilityIdentifier: "ReadingTable")
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")

        // Go back to the reading list panel
        BrowserUtils.openLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: ImageIdentifiers.readingList)

        // Make sure the article is marked as read
        tester().waitForView(withAccessibilityLabel: "Readable page, read, localhost")
        tester().waitForView(withAccessibilityLabel: "localhost")

        // Remove the list entry
        // Workaround for iPad, the swipe gesture is not controlled and the Remove button
        // is kept behing the Mark as read and so the test fails
        if BrowserUtils.iPad() {
            // Add once iPad tests run
        } else {
            let firstIndexPath = IndexPath(row: 0, section: 0)
            let list = tester().waitForView(withAccessibilityIdentifier: "ReadingTable") as? UITableView
            
            let row = tester().waitForCell(at: firstIndexPath, inTableViewWithAccessibilityIdentifier: "ReadingTable")
            tester().swipeView(withAccessibilityLabel: row?.accessibilityLabel, value: row?.accessibilityValue, in: KIFSwipeDirection.left)
            tester().tapView(withAccessibilityLabel: "Remove")
        }

        // check the entry no longer exist
        waitForEmptyReadingList()

        // Close Reading (and so Library) panel
        BrowserUtils.closeLibraryMenu(tester())
    }

    override func tearDown() {
        BrowserUtils.resetToAboutHomeKIF(tester())
        tester().wait(forTimeInterval: 3)
        BrowserUtils.clearPrivateDataKIF(tester())
        super.tearDown()
    }
}
