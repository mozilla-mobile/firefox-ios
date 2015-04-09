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

    /**
     * Tests for listed history visits
     */
    func testHistoryUI() {
        // Load a page
        tester().tapViewWithAccessibilityLabel("URL")
        let url1 = "\(webRoot)/?page=1"
        tester().clearTextFromAndThenEnterText("\(url1)\n", intoViewWithAccessibilityLabel: "Address and Search")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Load a different page
        tester().tapViewWithAccessibilityLabel("URL")
        let url2 = "\(webRoot)/?page=2"
        tester().clearTextFromAndThenEnterText("\(url2)\n", intoViewWithAccessibilityLabel: "Address and Search")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        // Check that both appear in the history home panel
        tester().tapViewWithAccessibilityLabel("URL")
        tester().tapViewWithAccessibilityLabel("History")
        let firstHistoryRow = tester().waitForViewWithAccessibilityLabel(url1) as! UITableViewCell
        XCTAssertNotNil(firstHistoryRow.imageView?.image)
        let secondHistoryRow = tester().waitForViewWithAccessibilityLabel(url2) as! UITableViewCell
        XCTAssertNotNil(secondHistoryRow.imageView?.image)

        tester().tapViewWithAccessibilityLabel("Cancel")
    }
}
