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

    override func tearDown() {
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

        return urls
    }

    func testClearsTopSitesPanel() {
        let urls = visitSites(2)

        // assert sites appear in top sites
        BrowserUtils.resetToAboutHome(tester())
        tester().tapViewWithAccessibilityLabel("Top sites")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(urls[0].title, error: nil), "Expected to have top site panel \(urls[0])")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(urls[1].title, error: nil), "Expected to have top site panel \(urls[1])")

        clearPrivateData(true)

        // assert sites no longer appear in top sites
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")

        XCTAssertFalse(tester().tryFindingViewWithAccessibilityLabel(urls[0].title, error: nil), "Expected to have removed top site panel \(urls[0])")
        XCTAssertFalse(tester().tryFindingViewWithAccessibilityLabel(urls[1].title, error: nil), "Expected to have removed top site panel \(urls[1])")
    }

    func testCancelDoesNotClearTopSitesPanel() {
        let urls = visitSites(2)

        // assert sites appear in top sites
        BrowserUtils.resetToAboutHome(tester())
        tester().tapViewWithAccessibilityLabel("Top sites")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(urls[0].title, error: nil), "Expected to have top site panel \(urls[0])")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(urls[1].title, error: nil), "Expected to have top site panel \(urls[1])")

        // clear private data
        clearPrivateData(false)

        // assert sites still appear in top sites
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")

        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(urls[0].title, error: nil), "Expected to have removed top site panel \(urls[0])")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(urls[1].title, error: nil), "Expected to have removed top site panel \(urls[1])")
    }

    func testClearsHistoryPanel() {
        let urls = visitSites(2)

        BrowserUtils.resetToAboutHome(tester())

        // check history
        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)", url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url1, error: nil), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url2, error: nil), "Expected to have history row \(url2)")

        clearPrivateData(true)

        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")

        // check history cleared
        tester().tapViewWithAccessibilityLabel("History")
        XCTAssertFalse(tester().tryFindingViewWithAccessibilityLabel(url1, error: nil), "Expected to have removed history row \(url1)")
        XCTAssertFalse(tester().tryFindingViewWithAccessibilityLabel(url2, error: nil), "Expected to have removed history row \(url2)")

    }

    func testCancelDataDoesNotClearHistoryPanel() {
        let urls = visitSites(2)

        BrowserUtils.resetToAboutHome(tester())

        // check history
        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)", url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url1, error: nil), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url2, error: nil), "Expected to have history row \(url2)")

        clearPrivateData(false)

        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")

        // check history not cleared
        tester().tapViewWithAccessibilityLabel("History")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url1, error: nil), "Expected to have removed history row \(url1)")
        XCTAssertTrue(tester().tryFindingViewWithAccessibilityLabel(url2, error: nil), "Expected to have removed history row \(url2)")
        
    }
}