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
            .replacingOccurrences(of: "127.0.0.1", with: "localhost", options: NSString.CompareOptions(), range: nil)
        BrowserUtils.dismissFirstRunUI()
    }
    
    func enterUrl(url: String) {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_replaceText(url))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_typeText("\n"))
    }
    
    func waitForReadingList() {
        let readingList = GREYCondition(name: "wait until Reading List Add btn appears", block: { _ in
            var errorOrNil: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel("Add to Reading List"),
                                              grey_sufficientlyVisible()])
            EarlGrey.select(elementWithMatcher: matcher)
                .assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil == nil
            return success
        }).wait(withTimeout: 20)
        
        GREYAssertTrue(readingList, reason: "Can't be added to Reading List")
    }
    
    func waitForEmptyReadingList() {
        let readable = GREYCondition(name: "Check readable list is empty", block: { _ in
            var error: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel("Save pages to your Reading List by tapping the book plus icon in the Reader View controls."),
                                              grey_sufficientlyVisible()])
            EarlGrey.select(elementWithMatcher: matcher)
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
        enterUrl(url: url1)
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")
        
        // Add it to the reading list
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Reader View"))
            .perform(grey_tap())
        waitForReadingList()
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Add to Reading List"))
            .perform(grey_tap())
        
        // Open a new page
        let url2 = "\(webRoot!)/numberedPage.html?page=1"
        enterUrl(url: url2)
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        
        // Check that it appears in the reading list home panel
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url"))
            .perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Reading list"))
            .perform(grey_tap())
        
        // Tap to open it
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("localhost"))
            .perform(grey_tap())
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")
        
        // Remove it from the reading list
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Remove from Reading List"))
            .perform(grey_tap())
        
        // Check that it no longer appears in the reading list home panel
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url"))
            .perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Reading list"))
            .perform(grey_tap())
        
        waitForEmptyReadingList()
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("goBack")).perform(grey_tap())
    }
    
    func testReadingListAutoMarkAsRead() {
        // Load a page
        let url1 = "\(webRoot!)/readablePage.html"
        
        enterUrl(url: url1)
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")
        
        // Add it to the reading list
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Reader View"))
            .perform(grey_tap())
        waitForReadingList()
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Add to Reading List"))
            .perform(grey_tap())
        
        // Check that it appears in the reading list home panel and make sure it marked as unread
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url"))
            .perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Reading list"))
            .perform(grey_tap())
        tester().waitForView(withAccessibilityLabel: "Readable page, unread, localhost")
        // Select to Read
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("localhost"))
            .perform(grey_tap())
        tester().waitForWebViewElementWithAccessibilityLabel("Readable page")
        
        // Go back to the reading list panel
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url"))
            .perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Reading list"))
            .perform(grey_tap())
        
        // Make sure the article is marked as read
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Readable page"))
            .inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")!))
            .assert(grey_notNil())
        tester().waitForView(withAccessibilityLabel: "Readable page, read, localhost")
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("localhost"))
            .assert(grey_notNil())
        
        // Remove the list entry
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Readable page"))
            .inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")!))
            .perform(grey_swipeSlowInDirection(GREYDirection.left))
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Remove"))
            .inRoot(grey_kindOfClass(NSClassFromString("UISwipeActionStandardButton")!))
            .perform(grey_tap())
        
        // check the entry no longer exist
        waitForEmptyReadingList()
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("goBack")).perform(grey_tap())
    }
    
    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
        super.tearDown()
    }
}
