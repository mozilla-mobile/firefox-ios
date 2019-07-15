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
        BrowserUtils.configEarlGrey()
        BrowserUtils.dismissFirstRunUI()
    }

    func addHistoryItemPage(_ pageNo: Int) -> String {
        // Load a page
        let url = "\(webRoot!)/numberedPage.html?page=\(pageNo)"
        EarlGrey.selectElement(with: grey_accessibilityID("url")).perform(grey_tap())

        EarlGrey.selectElement(with: grey_accessibilityID("address")).perform(grey_replaceText(url))
        EarlGrey.selectElement(with: grey_accessibilityID("address")).perform(grey_typeText("\n"))
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
        BrowserUtils.openLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: "LibraryPanels.History")

        // Wait until the dialog shows up
        let listAppeared = GREYCondition(name: "Wait the history list to appear", block: {
            var errorOrNil: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel("Page 2"),
                                      grey_sufficientlyVisible()])
            EarlGrey.selectElement(with: matcher)
                .inRoot(grey_accessibilityID("History List"))
                .assert(grey_notNil(), error: &errorOrNil)
            return errorOrNil == nil
        }).wait(withTimeout: 20)
        GREYAssertTrue(listAppeared, reason: "Failed to display history")

        EarlGrey.selectElement(with: grey_accessibilityLabel("Page 2"))
            .inRoot(grey_accessibilityID("History List"))
            .assert(grey_sufficientlyVisible())
        EarlGrey.selectElement(with: grey_accessibilityLabel("Page 1"))
            .inRoot(grey_accessibilityID("History List"))
            .assert(grey_sufficientlyVisible())
        EarlGrey.selectElement(with: grey_accessibilityLabel("\(webRoot!)/numberedPage.html?page=2"))
            .inRoot(grey_accessibilityID("History List"))
            .assert(grey_sufficientlyVisible())
        EarlGrey.selectElement(with: grey_accessibilityLabel("\(webRoot!)/numberedPage.html?page=1"))
            .inRoot(grey_accessibilityID("History List"))
            .assert(grey_sufficientlyVisible())

        // Close History (and so Library) panel
        BrowserUtils.closeLibraryMenu(tester())
    }

    func testDeleteHistoryItemFromListWith2Items() {
        // add 2 history items
        let urls = addHistoryItems(2)

        // Check that both appear in the history home panel
        BrowserUtils.openLibraryMenu(tester())
        tester().waitForAnimationsToFinish()

        EarlGrey.selectElement(with: grey_accessibilityLabel(urls[0]))
            .perform(grey_longPress())
        EarlGrey.selectElement(with: grey_accessibilityLabel("Delete from History"))
            .inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")!))
            .perform(grey_tap())

        // The second history entry still exists
        EarlGrey.selectElement(with: grey_accessibilityLabel(urls[1]))
            .inRoot(grey_kindOfClass(NSClassFromString("UITableViewCellContentView")!))
            .assert(grey_notNil())

        // check page 1 does not exist
        let historyRemoved = GREYCondition(name: "Check entry is removed", block: {
            var errorOrNil: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel(urls[0]),
                                              grey_sufficientlyVisible()])
            EarlGrey.selectElement(with: matcher).assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil != nil
            return success
        }).wait(withTimeout: 5)
        GREYAssertTrue(historyRemoved, reason: "Failed to remove history")

        // Close History (and so Library) panel
        BrowserUtils.closeLibraryMenu(tester())
    }

    func testDeleteHistoryItemFromListWithMoreThan100Items() {

        for pageNo in 1...102 {
            BrowserUtils.addHistoryEntry("Page \(pageNo)", url: URL(string: "\(webRoot!)/numberedPage.html?page=\(pageNo)")!)
        }
        tester().wait(forTimeInterval: 2)
        let urlToDelete = "\(webRoot!)/numberedPage.html?page=\(102)"
        let oldestUrl = "\(webRoot!)/numberedPage.html?page=\(101)"
        tester().waitForAnimationsToFinish()
        BrowserUtils.openLibraryMenu(tester())
        tester().waitForAnimationsToFinish()
        tester().waitForView(withAccessibilityIdentifier: "LibraryPanels.History")
        tester().waitForView(withAccessibilityLabel: "Page 102")

        EarlGrey.selectElement(with: grey_accessibilityLabel("Page 102")).inRoot(grey_kindOfClass(NSClassFromString("UITableView")!)).perform(grey_swipeSlowInDirectionWithStartPoint(.left, 0.6, 0.6))
        if !BrowserUtils.iPad() {
            EarlGrey.selectElement(with:grey_accessibilityLabel("Delete"))
                .inRoot(grey_kindOfClass(NSClassFromString("UISwipeActionStandardButton")!))
                .perform(grey_tap())
        }

        // The history list still exists
        EarlGrey.selectElement(with: grey_accessibilityID("History List"))
            .assert(grey_notNil())
        EarlGrey.selectElement(with: grey_accessibilityLabel(oldestUrl))
            .assert(grey_notNil())

        // check page 1 does not exist
        let historyRemoved = GREYCondition(name: "Check entry is removed", block: {
            var errorOrNil: NSError?
            let matcher = grey_allOf([grey_accessibilityLabel(urlToDelete),
                                              grey_sufficientlyVisible()])
            EarlGrey.selectElement(with:matcher).assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil != nil
            return success
        }).wait(withTimeout: 5)
        GREYAssertTrue(historyRemoved, reason: "Failed to remove history")

        // Close History (and so Library) panel
        BrowserUtils.closeLibraryMenu(tester())
    }

    override func tearDown() {
        BrowserUtils.clearPrivateData()
        super.tearDown()
    }
}
