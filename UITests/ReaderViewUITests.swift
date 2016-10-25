/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class ReaderViewUITests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        super.setUp()
        // We undo the localhost/127.0.0.1 switch in order to get 'localhost' in accessibility labels.
        webRoot = SimplePageServer.start()
            .stringByReplacingOccurrencesOfString("127.0.0.1", withString: "localhost", options: NSStringCompareOptions(), range: nil)
        BrowserUtils.dismissFirstRunUI(tester())
    }
    
    /**
    * Tests reader view UI with reader optimized content
    */
    func testReaderViewUI() {
        loadReaderContent()
        addToReadingList()
        markAsReadFromReaderView()
        markAsUnreadFromReaderView()
        
        // Need to comment out below routines, since swiping (to expose buttons) does not work with the Accessibility Label given
        //markAsReadFromReadingList()
        //markAsUnreadFromReadingList()
        //removeFromReadingList()
        //addToReadingList()
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
        tester().waitForViewWithAccessibilityLabel("Reader View Test, unread, localhost")

        // TODO: Check for rows in this table

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func markAsReadFromReaderView() {
        tester().tapViewWithAccessibilityLabel("Mark as Read")
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().waitForViewWithAccessibilityLabel("Reader View Test")
        tester().swipeViewWithAccessibilityLabel("Reader View Test", inDirection: KIFSwipeDirection.Left)
        tester().waitForViewWithAccessibilityLabel("Mark as Unread")
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func markAsUnreadFromReaderView() {
        tester().tapViewWithAccessibilityLabel("Mark as Unread")
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().swipeViewWithAccessibilityLabel("Reader View Test", inDirection: KIFSwipeDirection.Left)
        tester().waitForViewWithAccessibilityLabel("Mark as Read")
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func markAsReadFromReadingList() {
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().swipeViewWithAccessibilityLabel("Reader View Test", inDirection: KIFSwipeDirection.Left)
        tester().tapViewWithAccessibilityLabel("Mark as Read")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Mark as Unread")
    }

    func markAsUnreadFromReadingList() {
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().swipeViewWithAccessibilityLabel("Reader View Test", inDirection: KIFSwipeDirection.Left)
        tester().tapViewWithAccessibilityLabel("Mark as Unread")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Mark as Read")
    }
 
    func removeFromReadingList() {
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Reading list")
        tester().swipeViewWithAccessibilityLabel("Reader View Test read", inDirection: KIFSwipeDirection.Left)
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
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }

}
