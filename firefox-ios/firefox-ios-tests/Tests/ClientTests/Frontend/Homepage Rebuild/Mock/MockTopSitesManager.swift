// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client

final class MockTopSitesManager: TopSitesManagerInterface {
    var getOtherSitesCalledCount = 0
    var fetchSponsoredSitesCalledCount = 0
    var recalculateTopSitesCalledCount = 0

    var removeTopSiteCalledCount = 0
    var pinTopSiteCalledCount = 0
    var unpinTopSiteCalledCount = 0

    func getOtherSites() async -> [TopSiteState] {
        getOtherSitesCalledCount += 1
        return createSites(count: 15, subtitle: ": otherSites")
    }

    func fetchSponsoredSites() async -> [Site] {
        fetchSponsoredSitesCalledCount += 1

        let contiles = MockSponsoredProvider.defaultSuccessData
        return contiles.compactMap { Site.createSponsoredSite(fromContile: $0) }
    }

    func recalculateTopSites(otherSites: [TopSiteState], sponsoredSites: [Site]) -> [TopSiteState] {
        recalculateTopSitesCalledCount += 1
        return createSites(subtitle: ": total top sites")
    }

    func createSites(count: Int = 30, subtitle: String = "") -> [TopSiteState] {
        var sites = [TopSiteState]()
        (0..<count).forEach {
            let site = Site.createBasicSite(url: "www.url\($0).com",
                                            title: "Title \($0) \(subtitle)")
            sites.append(TopSiteState(site: site))
        }
        return sites
    }

    func removeTopSite(_ site: Site) {
        removeTopSiteCalledCount += 1
    }

    func pinTopSite(_ site: Site) {
        pinTopSiteCalledCount += 1
    }

    func unpinTopSite(_ site: Site) {
        unpinTopSiteCalledCount += 1
    }
}
