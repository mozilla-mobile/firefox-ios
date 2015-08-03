/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import UIKit

class ClearPrivateDataTests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    override func afterEach() {
        BrowserUtils.resetToAboutHome(tester())
    }


    override func beforeAll() {
        BrowserUtils.resetToAboutHome(tester())
    }

    func clearPrivateData(shouldClear: Bool) {
        // clear private data
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().waitForTappableViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().waitForViewWithAccessibilityLabel("Clear Private Data")
        tester().tapViewWithAccessibilityLabel("Clear Private Data")
        tester().waitForViewWithAccessibilityLabel("Clear Everything")
        if shouldClear {
            tester().tapViewWithAccessibilityLabel("Clear")
        } else {
            tester().tapViewWithAccessibilityLabel("Cancel")
        }
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Clear Everything")

        tester().tapViewWithAccessibilityLabel("Done")
        // on the ipad air sometimes we will find ourselves already out of the tab tray so no need to click 'home'
        if tester().tryFindingViewWithAccessibilityLabel("home", error: nil) {
            tester().tapViewWithAccessibilityLabel("home")
        }
    }

    func visitSites(noOfSites: Int) -> [(title: String, url: String)] {
        var urls: [(title: String, url: String)] = []
        for pageNo in 1...noOfSites {
            // visit 2 sites
            tester().tapViewWithAccessibilityIdentifier("url")
            let url = "\(webRoot)/numberedPage.html?page=\(pageNo)"
            tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
            tester().waitForWebViewElementWithAccessibilityLabel("Page \(pageNo)")
            let tuple: (title: String, url: String) = ("Page \(pageNo)", url)
            urls.append(tuple)
        }
        BrowserUtils.resetToAboutHome(tester())
        return urls
    }

    func testClearsTopSitesPanel() {
        let urls = visitSites(2)

        tester().tapViewWithAccessibilityLabel("Top sites")

        // Only one will be found -- we collapse by domain.
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(urls[0].title, error: nil), "Expected to have top site panel \(urls[0])")

        clearPrivateData(true)

        XCTAssertFalse(tester().tryFindingViewWithAccessibilityLabel(urls[0].title, error: nil), "Expected to have removed top site panel \(urls[0])")
        XCTAssertFalse(tester().tryFindingViewWithAccessibilityLabel(urls[1].title, error: nil), "We shouldn't find the other URL, either.")
    }

    func testCancelDoesNotClearTopSitesPanel() {
        let urls = visitSites(2)

        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(urls[0].title, error: nil), "Expected to have top site panel \(urls[0])")

        clearPrivateData(false)

        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(urls[0].title, error: nil), "Expected to have not removed top site panel \(urls[0])")
        XCTAssertFalse(tester().tryFindingViewWithAccessibilityLabel(urls[1].title, error: nil), "The other never existed.")
    }

    func testClearsHistoryPanel() {
        let urls = visitSites(2)

        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)", url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url1, error: nil), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url2, error: nil), "Expected to have history row \(url2)")

        clearPrivateData(true)

        tester().tapViewWithAccessibilityLabel("History")
        XCTAssertFalse(tester().tryFindingViewWithAccessibilityLabel(url1, error: nil), "Expected to have removed history row \(url1)")
        XCTAssertFalse(tester().tryFindingViewWithAccessibilityLabel(url2, error: nil), "Expected to have removed history row \(url2)")

    }

    func testCancelDoesNotClearHistoryPanel() {
        let urls = visitSites(2)

        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)", url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url1, error: nil), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url2, error: nil), "Expected to have history row \(url2)")

        clearPrivateData(false)

        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url1, error: nil), "Expected to not have removed history row \(url1)")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url2, error: nil), "Expected to not have removed history row \(url2)")
    }
}