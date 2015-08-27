/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class HistoryTests: KIFTestCase {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    func addHistoryItemPage(pageNo: Int) -> String {
        // Load a page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url = "\(webRoot)/numberedPage.html?page=\(pageNo)"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page \(pageNo)")
        return "Page \(pageNo), \(url)"
    }

    func addHistoryItems(noOfItemsToAdd: Int) -> [String] {
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
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("History")


        let firstHistoryRow = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "History List")
        XCTAssertNotNil(firstHistoryRow.imageView?.image)
        XCTAssertEqual(firstHistoryRow.textLabel!.text!, "Page 2")
        XCTAssertEqual(firstHistoryRow.detailTextLabel!.text!, "\(webRoot)/numberedPage.html?page=2")


        let secondHistoryRow = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 1, inSection: 0), inTableViewWithAccessibilityIdentifier: "History List")
        XCTAssertNotNil(secondHistoryRow.imageView?.image)
        XCTAssertEqual(secondHistoryRow.textLabel!.text!, "Page 1")
        XCTAssertEqual(secondHistoryRow.detailTextLabel!.text!, "\(webRoot)/numberedPage.html?page=1")

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func testDeleteHistoryItemFromListWith2Items() {
        // add 2 history items
        // delete all history items

        let urls = addHistoryItems(2)

        // Check that both appear in the history home panel
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("History")

        tester().swipeViewWithAccessibilityLabel(urls[0], inDirection: KIFSwipeDirection.Left)
        tester().tapViewWithAccessibilityLabel("Remove")

        let secondHistoryRow = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "History List")
        XCTAssertNotNil(secondHistoryRow.imageView?.image)

        if let keyWindow = UIApplication.sharedApplication().keyWindow {
            XCTAssertNil(keyWindow.accessibilityElementWithLabel(urls[0]), "page 1 should have been deleted")
        }

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func testDeleteHistoryItemFromListWithMoreThan100Items() {
        do {
            try tester().tryFindingTappableViewWithAccessibilityLabel("Top sites")
            tester().tapViewWithAccessibilityLabel("Top sites")
        } catch _ {
        }
        for pageNo in 1...102 {
            BrowserUtils.addHistoryEntry("Page \(pageNo)", url: NSURL(string: "\(webRoot)/numberedPage.html?page=\(pageNo)")!)
        }
        let urlToDelete = "Page \(102), \(webRoot)/numberedPage.html?page=\(102)"

        tester().tapViewWithAccessibilityLabel("History")

        tester().swipeViewWithAccessibilityLabel(urlToDelete, inDirection: KIFSwipeDirection.Left)
        tester().tapViewWithAccessibilityLabel("Remove")

        let secondHistoryRow = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "History List")
        XCTAssertNotNil(secondHistoryRow.imageView?.image)
        if let keyWindow = UIApplication.sharedApplication().keyWindow {
            XCTAssertNil(keyWindow.accessibilityElementWithLabel(urlToDelete), "page 102 should have been deleted")
        }
    }

    override func tearDown() {
        BrowserUtils.clearHistoryItems(tester(), numberOfTests: 2)
    }
}
