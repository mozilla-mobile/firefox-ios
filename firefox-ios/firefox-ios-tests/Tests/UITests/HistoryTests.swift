// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

class HistoryTests: KIFTestCase {
    
    typealias a11y = AccessibilityIdentifiers.LibraryPanels.HistoryPanel
    
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    func addHistoryItemPage(_ pageNo: Int) -> String {
        // Load a page
        let url = "\(webRoot!)/numberedPage.html?page=\(pageNo)"

        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
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
        tester().tapView(withAccessibilityIdentifier: StandardImageIdentifiers.Large.history)

        // Wait until the dialog shows up
        tester().waitForAnimationsToFinish()
        tester().waitForView(withAccessibilityLabel: "Page 2")
        
        tester().waitForView(withAccessibilityLabel: "Page 1")
        tester().waitForView(withAccessibilityLabel: "\(webRoot!)/numberedPage.html?page=2")

        tester().waitForView(withAccessibilityLabel: "\(webRoot!)/numberedPage.html?page=1")


        // Close History (and so Library) panel
        BrowserUtils.closeLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: "url")
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
        tester().waitForAnimationsToFinish(withTimeout: 10)
        tester().waitForView(withAccessibilityIdentifier: StandardImageIdentifiers.Large.history)
        tester().tapView(withAccessibilityIdentifier: StandardImageIdentifiers.Large.history)
        tester().waitForAnimationsToFinish(withTimeout: 10)
        tester().waitForView(withAccessibilityLabel: "Page 102")

        let firstIndexPath = IndexPath(row: 4, section: 1)
        let row = tester().waitForCell(at: firstIndexPath, inTableViewWithAccessibilityIdentifier: a11y.tableView)
        tester().swipeView(withAccessibilityLabel: row?.accessibilityLabel, value: row?.accessibilityValue, in: KIFSwipeDirection.left)
     
        if !BrowserUtils.iPad() {
            tester().tapView(withAccessibilityLabel: "Delete")
        }

        // The history list still exists
        tester().waitForView(withAccessibilityIdentifier: a11y.tableView)
        tester().waitForView(withAccessibilityLabel: oldestUrl)

        // check page 1 does not exist
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Page 102")

        // Close History (and so Library) panel
        BrowserUtils.closeLibraryMenu(tester())
        tester().tapView(withAccessibilityIdentifier: "url")
    }

    override func tearDown() {
        BrowserUtils.clearPrivateDataKIF(tester())
        super.tearDown()
    }
}
