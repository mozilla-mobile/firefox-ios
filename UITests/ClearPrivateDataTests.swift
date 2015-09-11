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
        BrowserUtils.clearHistoryItems(tester())
    }
    
    func openClearPrivateDataDialog(shouldClear shouldClear: Bool) {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Clear Private Data")

        if shouldClear {
            tester().tapViewWithAccessibilityLabel("Clear Private Data", traits: UIAccessibilityTraitButton)
        }

        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")
    }

    func visitSites(noOfSites noOfSites: Int) -> [(title: String, domain: String, url: String)] {
        var urls: [(title: String, domain: String, url: String)] = []
        for pageNo in 1...noOfSites {
            tester().tapViewWithAccessibilityIdentifier("url")
            let url = "\(webRoot)/numberedPage.html?page=\(pageNo)"
            tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
            tester().waitForWebViewElementWithAccessibilityLabel("Page \(pageNo)")
            let tuple: (title: String, domain: String, url: String) = ("Page \(pageNo)", NSURL(string: url)!.normalizedHost()!, url)
            urls.append(tuple)
        }
        BrowserUtils.resetToAboutHome(tester())
        return urls
    }

    func anyDomainsExistOnTopSites(domains: Set<String>) {
        for domain in domains {
            if self.tester().viewExistsWithLabel(domain) {
                return
            }
        }
        XCTFail("Couldn't find any domains in top sites.")
    }

    func testClearsTopSitesPanel() {
        let urls = visitSites(noOfSites: 2)
        let domains = Set<String>(urls.map { $0.domain })

        tester().tapViewWithAccessibilityLabel("Top sites")

        // Only one will be found -- we collapse by domain.
        anyDomainsExistOnTopSites(domains)

        openClearPrivateDataDialog(shouldClear: true)

        XCTAssertFalse(tester().viewExistsWithLabel(urls[0].title), "Expected to have removed top site panel \(urls[0])")
        XCTAssertFalse(tester().viewExistsWithLabel(urls[1].title), "We shouldn't find the other URL, either.")
    }

    func testCancelDoesNotClearTopSitesPanel() {
        let urls = visitSites(noOfSites: 2)
        let domains = Set<String>(urls.map { $0.domain })

        anyDomainsExistOnTopSites(domains)
        openClearPrivateDataDialog(shouldClear: false)
        anyDomainsExistOnTopSites(domains)
    }

    func testClearsHistoryPanel() {
        let urls = visitSites(noOfSites: 2)

        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)"
        let url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().viewExistsWithLabel(url1), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().viewExistsWithLabel(url2), "Expected to have history row \(url2)")

        openClearPrivateDataDialog(shouldClear: true)

        tester().tapViewWithAccessibilityLabel("History")
        XCTAssertFalse(tester().viewExistsWithLabel(url1), "Expected to have removed history row \(url1)")
        XCTAssertFalse(tester().viewExistsWithLabel(url2), "Expected to have removed history row \(url2)")
    }

    func testCancelDoesNotClearHistoryPanel() {
        let urls = visitSites(noOfSites: 2)

        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)"
        let url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().viewExistsWithLabel(url1), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().viewExistsWithLabel(url2), "Expected to have history row \(url2)")

        openClearPrivateDataDialog(shouldClear: false)

        XCTAssertTrue(tester().viewExistsWithLabel(url1), "Expected to not have removed history row \(url1)")
        XCTAssertTrue(tester().viewExistsWithLabel(url2), "Expected to not have removed history row \(url2)")
    }
}
