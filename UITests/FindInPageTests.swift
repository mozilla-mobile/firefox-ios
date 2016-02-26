/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class FindInPageTests: KIFTestCase {
    private static let LongPressDuration: NSTimeInterval = 2

    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    func testFindFromSelection() {
        let testURL = "\(webRoot)/findPage.html"

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(testURL)\n")
        let webView = tester().waitForViewWithAccessibilityLabel("Web content") as! WKWebView
        tester().waitForWebViewElementWithAccessibilityLabel("nullam")

        // Ensure the find-in-page bar is visible by looking at views.
        openFindInPageBar(webView)
        XCTAssertTrue(tester().viewExistsWithLabel("Done"))
        XCTAssertTrue(tester().viewExistsWithLabel("Next in-page result"))
        XCTAssertTrue(tester().viewExistsWithLabel("Previous in-page result"))

        // Test previous/next buttons.
        try! tester().tryFindingViewWithAccessibilityLabel("1/4")
        clickFindNext()
        try! tester().tryFindingViewWithAccessibilityLabel("2/4")
        clickFindNext()
        try! tester().tryFindingViewWithAccessibilityLabel("3/4")
        clickFindNext()
        try! tester().tryFindingViewWithAccessibilityLabel("4/4")
        clickFindNext()
        try! tester().tryFindingViewWithAccessibilityLabel("1/4")
        clickFindPrevious()
        try! tester().tryFindingViewWithAccessibilityLabel("4/4")
        clickFindPrevious()
        try! tester().tryFindingViewWithAccessibilityLabel("3/4")
        clickFindPrevious()
        try! tester().tryFindingViewWithAccessibilityLabel("2/4")
        clickFindPrevious()
        try! tester().tryFindingViewWithAccessibilityLabel("1/4")

        // Test a query with no matches.
        let findTextField = tester().waitForViewWithAccessibilityValue("nullam") as! UITextField
        findTextField.becomeFirstResponder()
        tester().enterTextIntoCurrentFirstResponder("z")
        let resultsView = tester().waitForViewWithAccessibilityLabel("0/0")
        XCTAssertFalse(resultsView.hidden)
        tester().clearTextFromFirstResponder()
        XCTAssertTrue(resultsView.hidden)

        // Make sure the selection menu still works with the bar already visible.
        openFindInPageBar(webView)
        try! tester().tryFindingViewWithAccessibilityLabel("1/4")

        // Make sure the bar disappears when reloading.
        tester().tapViewWithAccessibilityLabel("Reload")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("nullam")

        // Make sure the bar disappears when opening the tabs tray.
        openFindInPageBar(webView)
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Find Page")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("nullam")

        // Test that Done dismisses the toolbar.
        openFindInPageBar(webView)
        tester().tapViewWithAccessibilityLabel("Done")
        XCTAssertFalse(tester().viewExistsWithLabel("Done"))
        XCTAssertFalse(tester().viewExistsWithLabel("Next in-page result"))
        XCTAssertFalse(tester().viewExistsWithLabel("Previous in-page result"))
    }

    private func openFindInPageBar(webView: WKWebView) {
        // Make the selection menu appear. To keep things simple, the page has absolutely
        // positioned text at the top-left corner.
        webView.longPressAtPoint(CGPointZero, duration: FindInPageTests.LongPressDuration)

        // For some reason, we sometimes have to tap the selection
        // to make the selection menu appear.
        if !tester().viewExistsWithLabel("Find in Page") {
            webView.tapAtPoint(CGPointZero)
        }

        tester().tapViewWithAccessibilityLabel("Find in Page")
        tester().waitForViewWithAccessibilityValue("nullam")
    }

    private func clickFindNext() {
        tester().tapViewWithAccessibilityLabel("Next in-page result")
    }

    private func clickFindPrevious() {
        tester().tapViewWithAccessibilityLabel("Previous in-page result")
    }
}
