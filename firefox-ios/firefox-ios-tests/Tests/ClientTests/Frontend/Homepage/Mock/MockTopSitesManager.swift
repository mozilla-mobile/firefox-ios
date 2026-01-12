// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import XCTest

@testable import Client

final class MockTopSitesManager: TopSitesManagerInterface, @unchecked Sendable {
    var recalculateTopSitesCalledCount = 0
    var pinTopSiteCalledCount = 0

    // We add these completions since this method is called asynchronously
    var removeTopSiteCalled: () -> Void = {}
    var unpinTopSiteCalled: () -> Void = {}

    func getOtherSites() async -> [TopSiteConfiguration] {
        return createSites(count: 15, subtitle: ": otherSites")
    }

    func fetchSponsoredSites() async -> [Site] {
        let unifiedTiles = MockSponsoredTileData.defaultSuccessData
        return unifiedTiles.compactMap { Site.createSponsoredSite(fromUnifiedTile: $0) }
    }

    func recalculateTopSites(otherSites: [TopSiteConfiguration], sponsoredSites: [Site]) -> [TopSiteConfiguration] {
        recalculateTopSitesCalledCount += 1
        XCTAssertTrue(Thread.isMainThread)
        return createSites(subtitle: ": total top sites")
    }

    func createSites(count: Int = 30, subtitle: String = "") -> [TopSiteConfiguration] {
        var sites = [TopSiteConfiguration]()
        (0..<count).forEach {
            let site = Site.createBasicSite(url: "www.url\($0).com",
                                            title: "Title \($0) \(subtitle)")
            sites.append(TopSiteConfiguration(site: site))
        }
        return sites
    }

    func removeTopSite(_ site: Site) async {
        removeTopSiteCalled()
    }

    func pinTopSite(_ site: Site) {
        pinTopSiteCalledCount += 1
    }

    func unpinTopSite(_ site: Site) async {
        unpinTopSiteCalled()
    }
}
