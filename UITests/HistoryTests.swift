/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class HistoryTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()        //If it is a first run, first run window should be gone
        BrowserUtils.dismissFirstRunUI(tester())
    }

    func addHistoryItemPage(_ pageNo: Int) -> String {
        // Load a page
        tester().tapView(withAccessibilityIdentifier: "url")
        let url = "\(webRoot)/numberedPage.html?page=\(pageNo)"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page \(pageNo)")
        return "Page \(pageNo), \(url)"
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
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "History")

        let firstHistoryRow = tester().waitForCell(at: IndexPath(row: 0, section: 0), inTableViewWithAccessibilityIdentifier: "History List")
        XCTAssertNotNil(firstHistoryRow?.imageView?.image)
        XCTAssertEqual(firstHistoryRow?.textLabel!.text!, "Page 2")
        XCTAssertEqual(firstHistoryRow?.detailTextLabel!.text!, "\(webRoot)/numberedPage.html?page=2")

        let secondHistoryRow = tester().waitForCell(at: IndexPath(row: 1, section: 0), inTableViewWithAccessibilityIdentifier: "History List")
        XCTAssertNotNil(secondHistoryRow?.imageView?.image)
        XCTAssertEqual(secondHistoryRow?.textLabel!.text!, "Page 1")
        XCTAssertEqual(secondHistoryRow?.detailTextLabel!.text!, "\(webRoot)/numberedPage.html?page=1")

        tester().tapView(withAccessibilityLabel: "Cancel")
    }

    //Disabled since font size cannot be changed from iOS 10
    /*
    func testChangingDynamicFontOnHistory() {
        _ = addHistoryItems(2)

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("History")

        let historyRow = tester().waitForCellAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), inTableViewWithAccessibilityIdentifier: "History List")
        let size = historyRow.textLabel?.font.pointSize

        DynamicFontUtils.bumpDynamicFontSize(tester())
        let bigSize = historyRow.textLabel?.font.pointSize

        DynamicFontUtils.lowerDynamicFontSize(tester())
        let smallSize = historyRow.textLabel?.font.pointSize

        XCTAssertGreaterThan(bigSize!, size!)
        XCTAssertGreaterThanOrEqual(size!, smallSize!)
    }
    */

    func testDeleteHistoryItemFromListWith2Items() {
        // add 2 history items
        // delete all history items

        let urls = addHistoryItems(2)

        // Check that both appear in the history home panel
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "History")

        tester().swipeView(withAccessibilityLabel: urls[0], in: KIFSwipeDirection.left)
        tester().tapView(withAccessibilityLabel: "Remove")

        let secondHistoryRow = tester().waitForCell(at: IndexPath(row: 0, section: 0), inTableViewWithAccessibilityIdentifier: "History List")
        XCTAssertNotNil(secondHistoryRow?.imageView?.image)

        if let keyWindow = UIApplication.shared.keyWindow {
            XCTAssertNil(keyWindow.accessibilityElement(withLabel: urls[0]), "page 1 should have been deleted")
        }

        tester().tapView(withAccessibilityLabel: "Cancel")
    }

    func testDeleteHistoryItemFromListWithMoreThan100Items() {
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: "Top sites")
            tester().tapView(withAccessibilityLabel: "Top sites")
        } catch _ {
        }
        for pageNo in 1...102 {
            BrowserUtils.addHistoryEntry("Page \(pageNo)", url: URL(string: "\(webRoot)/numberedPage.html?page=\(pageNo)")!)
        }
        let urlToDelete = "Page \(102), \(webRoot)/numberedPage.html?page=\(102)"

        tester().tapView(withAccessibilityLabel: "History")
        tester().waitForView(withAccessibilityLabel: urlToDelete)
        tester().swipeView(withAccessibilityLabel: urlToDelete, in: KIFSwipeDirection.left)
        tester().tapView(withAccessibilityLabel: "Remove")

        let secondHistoryRow = tester().waitForCell(at: IndexPath(row: 0, section: 0), inTableViewWithAccessibilityIdentifier: "History List")
        XCTAssertNotNil(secondHistoryRow?.imageView?.image)
        if let keyWindow = UIApplication.shared.keyWindow {
            XCTAssertNil(keyWindow.accessibilityElement(withLabel: urlToDelete), "page 102 should have been deleted")
        }
    }

    override func tearDown() {
        //DynamicFontUtils.restoreDynamicFontSize(tester())
        super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
}
