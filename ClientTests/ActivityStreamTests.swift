/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
@testable import Client
import Shared

class ActivityStreamTests: XCTestCase {

    func testDeletionOfSingleSuggestedSite() {
        let profile = MockProfile()
        let ASPanel = ActivityStreamPanel(profile: profile)
        let siteToDelete = ASPanel.defaultTopSites()[0]

        ASPanel.hideURLFromTopSites(NSURL(string: siteToDelete.url)!)
        let newSites = ASPanel.defaultTopSites()

        XCTAssertFalse(newSites.contains(siteToDelete, f: { (a, b) -> Bool in
            return a.url == b.url
        }))
    }

    func testDeletionOfAllDefaultSites() {
        let profile = MockProfile()
        let ASPanel = ActivityStreamPanel(profile: profile)
        let defaultSites = ASPanel.defaultTopSites()
        defaultSites.forEach({
            ASPanel.hideURLFromTopSites(NSURL(string: $0.url)!)
        })

        let newSites = ASPanel.defaultTopSites()
        XCTAssertTrue(newSites.isEmpty)
    }
}
