/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import UIKit

// Needs to be in sync with Client Clearables.
private enum Clearable: String {
    case History = "Browsing History"
    case Logins = "Saved Logins"
    case Cache = "Cache"
    case OfflineData = "Offline Website Data"
    case Cookies = "Cookies"
}

private let AllClearables = Set([Clearable.History, Clearable.Logins, Clearable.Cache, Clearable.OfflineData, Clearable.Cookies])

class ClearPrivateDataTests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    override func tearDown() {
        BrowserUtils.clearHistoryItems(tester())
    }

    private func clearPrivateData(clearables: Set<Clearable>) {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Clear Private Data")

        // Disable all items that we don't want to clear.
        for clearable in AllClearables.subtract(clearables) {
            // If we don't wait here, setOn:forSwitchWithAccessibilityLabel tries to use the UITableViewCell
            // instead of the UISwitch. KIF bug?
            tester().waitForViewWithAccessibilityLabel(clearable.rawValue)

            tester().setOn(false, forSwitchWithAccessibilityLabel: clearable.rawValue)
        }

        tester().tapViewWithAccessibilityLabel("Clear Private Data", traits: UIAccessibilityTraitButton)
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

        clearPrivateData([Clearable.History])

        XCTAssertFalse(tester().viewExistsWithLabel(urls[0].title), "Expected to have removed top site panel \(urls[0])")
        XCTAssertFalse(tester().viewExistsWithLabel(urls[1].title), "We shouldn't find the other URL, either.")
    }

    func testDisabledHistoryDoesNotClearTopSitesPanel() {
        let urls = visitSites(noOfSites: 2)
        let domains = Set<String>(urls.map { $0.domain })

        anyDomainsExistOnTopSites(domains)
        clearPrivateData(AllClearables.subtract([Clearable.History]))
        anyDomainsExistOnTopSites(domains)
    }

    func testClearsHistoryPanel() {
        let urls = visitSites(noOfSites: 2)

        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)"
        let url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().viewExistsWithLabel(url1), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().viewExistsWithLabel(url2), "Expected to have history row \(url2)")

        clearPrivateData([Clearable.History])

        tester().tapViewWithAccessibilityLabel("History")
        XCTAssertFalse(tester().viewExistsWithLabel(url1), "Expected to have removed history row \(url1)")
        XCTAssertFalse(tester().viewExistsWithLabel(url2), "Expected to have removed history row \(url2)")
    }

    func testDisabledHistoryDoesNotClearHistoryPanel() {
        let urls = visitSites(noOfSites: 2)

        tester().tapViewWithAccessibilityLabel("History")
        let url1 = "\(urls[0].title), \(urls[0].url)"
        let url2 = "\(urls[1].title), \(urls[1].url)"
        XCTAssertTrue(tester().viewExistsWithLabel(url1), "Expected to have history row \(url1)")
        XCTAssertTrue(tester().viewExistsWithLabel(url2), "Expected to have history row \(url2)")

        clearPrivateData(AllClearables.subtract([Clearable.History]))

        XCTAssertTrue(tester().viewExistsWithLabel(url1), "Expected to not have removed history row \(url1)")
        XCTAssertTrue(tester().viewExistsWithLabel(url2), "Expected to not have removed history row \(url2)")
    }
}
