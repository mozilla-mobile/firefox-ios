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
        var locationChangedTracked = false

        NSNotificationCenter.defaultCenter().addObserverForName("OnLocationChange", object: nil, queue: nil) { _ in
            locationChangedTracked = true
        }

        // First navigate to a normal tab and see that it tracks
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        tester().waitForTimeInterval(3)
        XCTAssertTrue(locationChangedTracked)

        locationChangedTracked = false

        // Then try doing the same thing for a private tab
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Add Private Tab")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityIdentifier("url")

        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        XCTAssertFalse(locationChangedTracked)
    }
}
