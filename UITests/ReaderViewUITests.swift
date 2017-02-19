/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class ReaderViewUITests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        // We undo the localhost/127.0.0.1 switch in order to get 'localhost' in accessibility labels.
        webRoot = SimplePageServer.start()
            .replacingOccurrences(of: "127.0.0.1", with: "localhost", options: NSString.CompareOptions(), range: nil)
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
        tester().tapView(withAccessibilityIdentifier: "url")
        let url = "\(webRoot)/readerContent.html"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url)\n")
        tester().tapView(withAccessibilityLabel: "Reader View")
    }

    func addToReadingList() {
        tester().tapView(withAccessibilityLabel: "Add to Reading List")
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")
        tester().waitForView(withAccessibilityLabel: "Reader View Test, unread, localhost")

        // TODO: Check for rows in this table

        tester().tapView(withAccessibilityLabel: "Cancel")
    }

    func markAsReadFromReaderView() {
        tester().tapView(withAccessibilityLabel: "Mark as Read")
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")
        tester().waitForView(withAccessibilityLabel: "Reader View Test")
        tester().swipeView(withAccessibilityLabel: "Reader View Test", in: KIFSwipeDirection.left)
        tester().waitForView(withAccessibilityLabel: "Mark as Unread")
        tester().tapView(withAccessibilityLabel: "Cancel")
    }

    func markAsUnreadFromReaderView() {
        tester().tapView(withAccessibilityLabel: "Mark as Unread")
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")
        tester().swipeView(withAccessibilityLabel: "Reader View Test", in: KIFSwipeDirection.left)
        tester().waitForView(withAccessibilityLabel: "Mark as Read")
        tester().tapView(withAccessibilityLabel: "Cancel")
    }

    func markAsReadFromReadingList() {
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")
        tester().swipeView(withAccessibilityLabel: "Reader View Test", in: KIFSwipeDirection.left)
        tester().tapView(withAccessibilityLabel: "Mark as Read")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForView(withAccessibilityLabel: "Mark as Unread")
    }

    func markAsUnreadFromReadingList() {
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")
        tester().swipeView(withAccessibilityLabel: "Reader View Test", in: KIFSwipeDirection.left)
        tester().tapView(withAccessibilityLabel: "Mark as Unread")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForView(withAccessibilityLabel: "Mark as Read")
    }
 
    func removeFromReadingList() {
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")
        tester().swipeView(withAccessibilityLabel: "Reader View Test read", in: KIFSwipeDirection.left)
        tester().tapView(withAccessibilityLabel: "Remove")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Reader View Test")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForView(withAccessibilityLabel: "Add to Reading List")
    }

    func removeFromReadingListInView() {
        tester().tapView(withAccessibilityLabel: "Remove from Reading List")
        tester().waitForView(withAccessibilityLabel: "Add to Reading List")
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "Reading list")
        
        // TODO: Check for rows in this table
        
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForView(withAccessibilityLabel: "Add to Reading List")
    }

    // TODO: Add a reader view display settings test

    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }

}
