/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import EarlGrey

class HistoryTests: KIFTestCase {
    fileprivate var webRoot: String!
    
    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI()
    }
    
    func addHistoryItemPage(_ pageNo: Int) -> String {
        // Load a page
        let url = "\(webRoot!)/numberedPage.html?page=\(pageNo)"
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_typeText("\(url)\n"))
        tester().waitForWebViewElementWithAccessibilityLabel("Page \(pageNo)")
        return url
    }
    
    func addHistoryItems(_ noOfItemsToAdd: Int) -> [String] {
        var urls = [String]()
        for index in 1...noOfItemsToAdd {
            urls.append(addHistoryItemPage(index))
        }
        return urls
    }
    
    /**
     * Tests for listed history visits
     */
    func testAddHistoryUI() {
        _ = addHistoryItems(2)
        
        // Check that both appear in the history home panel
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("History")).perform(grey_tap())
        
        let topConstraint = GREYLayoutConstraint(attribute: GREYLayoutAttribute.top,
                                                 relatedBy: GREYLayoutRelation.lessThanOrEqual,
                                                 toReferenceAttribute: GREYLayoutAttribute.bottom,
                                                 multiplier: 1.0,
                                                 constant: 0.0)
        
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Page 2"))
            .inRoot(grey_accessibilityID("History List"))
            .assert(grey_layout([topConstraint!], grey_accessibilityLabel("Page 1")))
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("\(webRoot!)/numberedPage.html?page=2"))
            .inRoot(grey_accessibilityID("History List"))
            .assert(grey_layout([topConstraint!], grey_accessibilityLabel("\(webRoot!)/numberedPage.html?page=1")))
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("\(webRoot!)/numberedPage.html?page=2"))
            .inRoot(grey_accessibilityID("History List"))
            .assert(grey_layout([topConstraint!], grey_accessibilityLabel("Page 1")))
        
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Cancel"))
            .inRoot(grey_kindOfClass(NSClassFromString("Client.InsetButton")!))
            .perform(grey_tap())
    }
    
    func testDeleteHistoryItemFromListWith2Items() {
        // add 2 history items
        let urls = addHistoryItems(2)
        
        // Check that both appear in the history home panel
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("History")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel(urls[0]))
            .perform(grey_swipeSlowInDirection(GREYDirection.left))
        
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Remove"))
            .inRoot(grey_kindOfClass(NSClassFromString("_UITableViewCellActionButton")!))
            .perform(grey_tap())
        
        // The second history entry still exists
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel(urls[1]))
            .inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")!))
            .assert(grey_notNil())
        
        // check page 1 does not exist
        let historyRemoved = GREYCondition(name: "Check entry is removed", block: { _ in
            var errorOrNil: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel(urls[0]),
                                              grey_sufficientlyVisible()])
            EarlGrey.select(elementWithMatcher: matcher).assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil != nil
            return success
        }).wait(withTimeout: 5)
        GREYAssertTrue(historyRemoved, reason: "Failed to remove history")
        
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Cancel"))
            .inRoot(grey_kindOfClass(NSClassFromString("Client.InsetButton")!))
            .perform(grey_tap())
    }
    
    func testDeleteHistoryItemFromListWithMoreThan100Items() {
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Top sites")).perform(grey_tap())
        
        for pageNo in 1...102 {
            BrowserUtils.addHistoryEntry("Page \(pageNo)", url: URL(string: "\(webRoot!)/numberedPage.html?page=\(pageNo)")!)
        }
        let urlToDelete = "\(webRoot!)/numberedPage.html?page=\(102)"
        let oldestUrl = "\(webRoot!)/numberedPage.html?page=\(101)"
        
        EarlGrey.select(elementWithMatcher:grey_accessibilityLabel("History"))
            .perform(grey_tap())
        EarlGrey.select(elementWithMatcher:grey_accessibilityLabel(urlToDelete))
            .perform(grey_swipeSlowInDirection(GREYDirection.left))
        EarlGrey.select(elementWithMatcher:grey_accessibilityLabel("Remove"))
            .inRoot(grey_kindOfClass(NSClassFromString("_UITableViewCellActionButton")!))
            .perform(grey_tap())
        
        // The history list still exists
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("History List"))
            .assert(grey_notNil())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel(oldestUrl))
            .assert(grey_notNil())
        
        // check page 1 does not exist
        let historyRemoved = GREYCondition(name: "Check entry is removed", block: { _ in
            var errorOrNil: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel(urlToDelete),
                                              grey_sufficientlyVisible()])
            EarlGrey.select(elementWithMatcher:matcher).assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil != nil
            return success
        }).wait(withTimeout: 5)
        GREYAssertTrue(historyRemoved, reason: "Failed to remove history")
    }
    
    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
        super.tearDown()
    }
}
