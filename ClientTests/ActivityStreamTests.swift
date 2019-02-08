/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest
@testable import Client
import Shared
import Storage
import Deferred
import SyncTelemetry

class ActivityStreamTests: XCTestCase {
    var profile: MockProfile!
    var panel: ActivityStreamPanel!

    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        self.panel = ActivityStreamPanel(profile: profile)
    }

    override func tearDown() {
Client/Application/AppDelegate.swift    }

    func testDeletionOfSingleSuggestedSite() {
        let siteToDelete = panel.defaultTopSites()[0]

        panel.hideURLFromTopSites(siteToDelete)
        let newSites = panel.defaultTopSites()

        XCTAssertFalse(newSites.contains(siteToDelete, f: { (a, b) -> Bool in
            return a.url == b.url
        }))
    }

    func testDeletionOfAllDefaultSites() {
        let defaultSites = panel.defaultTopSites()
        defaultSites.forEach({
            panel.hideURLFromTopSites($0)
        })

        let newSites = panel.defaultTopSites()
        XCTAssertTrue(newSites.isEmpty)
    }
}

fileprivate class MockTopSitesHistory: MockableHistory {
    let mockTopSites: [Site]

    init(sites: [Site]) {
        mockTopSites = sites
    }

    override func getTopSitesWithLimit(_ limit: Int) -> Deferred<Maybe<Cursor<Site>>> {
        return deferMaybe(ArrayCursor(data: mockTopSites))
    }

    override func getPinnedTopSites() -> Deferred<Maybe<Cursor<Site>>> {
        return deferMaybe(ArrayCursor(data: []))
    }

    override func updateTopSitesCacheIfInvalidated() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }
}
