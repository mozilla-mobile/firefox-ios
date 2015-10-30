/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class ReaderViewUITests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    /**
    * Tests reader view UI with reader optimized content
    */
    func testReaderViewUI() {
        loadReaderContent()
        addToReadingList()
        markAsReadFromReaderView()
        markAsUnreadFromReaderView()
        markAsReadFromReadingList()
        markAsUnreadFromReadingList()
        removeFromReadingList()
        addToReadingList()
        removeFromReadingListInView()
    }

    func loadReaderContent() {
        tester().tapViewWithAccessibilityIdentifier("url")
        let url = "\(webRoot)/readerContent.html"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().tapViewWithAccessibilityLabel("Reader View")
    }

    func addToReadingList() {
        tester().tapViewWithAccessibilityLabel("Add to Reading List")
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().waitForViewWithAccessibilityLabel("Reader View Test")

        // TODO: Check for rows in this table

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func markAsReadFromReaderView() {
        tester().tapViewWithAccessibilityLabel("Mark as Read")
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().swipeViewWithAccessibilityLabel("Reader View Test", inDirection: KIFSwipeDirection.Right)
        tester().waitForViewWithAccessibilityLabel("Mark as Unread")
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func markAsUnreadFromReaderView() {
        tester().tapViewWithAccessibilityLabel("Mark as Unread")
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().swipeViewWithAccessibilityLabel("Reader View Test", inDirection: KIFSwipeDirection.Right)
        tester().waitForViewWithAccessibilityLabel("Mark as Read")
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func markAsReadFromReadingList() {
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().swipeViewWithAccessibilityLabel("Reader View Test", inDirection: KIFSwipeDirection.Right)
        tester().tapViewWithAccessibilityLabel("Mark as Read")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Mark as Unread")
    }

    func markAsUnreadFromReadingList() {
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().swipeViewWithAccessibilityLabel("Reader View Test", inDirection: KIFSwipeDirection.Right)
        tester().tapViewWithAccessibilityLabel("Mark as Unread")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Mark as Read")
    }

    func removeFromReadingList() {
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().swipeViewWithAccessibilityLabel("Reader View Test", inDirection: KIFSwipeDirection.Left)
        tester().tapViewWithAccessibilityLabel("Remove")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Reader View Test")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Add to Reading List")
    }

    func removeFromReadingListInView() {
        tester().tapViewWithAccessibilityLabel("Remove from Reading List")
        tester().waitForViewWithAccessibilityLabel("Add to Reading List")
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        
        // TODO: Check for rows in this table
        
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Add to Reading List")
    }

    // TODO: Add a reader view display settings test

    override func tearDown() {
        BrowserUtils.clearHistoryItems(tester(), numberOfTests: 5)
    }
}
