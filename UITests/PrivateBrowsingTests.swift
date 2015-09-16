/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class PrivateBrowsingTests: KIFTestCase {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    func testPrivateTabDoesntTrackHistory() {

        // First navigate to a normal tab and see that it tracks
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        tester().waitForTimeInterval(3)

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("History")

        var tableView = tester().waitForViewWithAccessibilityIdentifier("History List") as! UITableView
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 1)
        tester().tapViewWithAccessibilityLabel("Cancel")

        // Then try doing the same thing for a private tab
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Add Private Tab")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityIdentifier("url")

        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("History")

        tableView = tester().waitForViewWithAccessibilityIdentifier("History List") as! UITableView
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 1)
    }

    func testPrivateTabDoesntStoreCookies() {
        // First, verify that when we go to a normal tab, we properly save a cookie
        let url1 = "\(webRoot)/cookie.html"
        let url2 = "\(webRoot)/numberedPage.html?page=1"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForTimeInterval(3)

        var webView = tester().waitForViewWithAccessibilityLabel("Web content") as! WKWebView

//        verifyWebViewHasStoredCookie(webView)

        tester().tapViewWithAccessibilityLabel("Show Tabs")

        let tabCell = tester().waitForTappableViewWithAccessibilityLabel("Cookie Test") as! UICollectionViewCell
        let action = tabCell.accessibilityCustomActions?.filter { $0.name == "Close" }.first
        XCTAssertNotNil(action)
        action!.target!.performSelector(action!.selector, withObject:action!)
        tester().waitForTimeInterval(2)

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url2)\n")
        tester().waitForTimeInterval(3)

        XCTAssertEqual(NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies?.count, 1, "Saved one cookie in cookie.html page")

        // Then, verify that when we go to a private tab, we don't save the cookie
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Add Private Tab")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForTimeInterval(3)

        webView = tester().waitForViewWithAccessibilityLabel("Web content") as! WKWebView
    }

//    private func verifyWebViewHasStoredCookie(webView: WKWebView) {
//        var stepResult = KIFTestStepResult.Wait
//        webView.evaluateJavaScript("document.cookie != null") { (result, error) -> Void in
//            guard let result = result as? Bool where error == nil else {
//                stepResult = KIFTestStepResult.Failure
//                return
//            }
//            stepResult = result ? KIFTestStepResult.Success : KIFTestStepResult.Failure
//        }
//        tester().runBlock({ _ in
//            return stepResult
//        }, timeout: 5)
//    }
}
