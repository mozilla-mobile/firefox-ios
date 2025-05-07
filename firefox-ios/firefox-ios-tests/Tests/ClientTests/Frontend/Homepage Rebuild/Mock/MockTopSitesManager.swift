// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client

final class MockTopSitesManager: TopSitesManagerInterface {
    var getOtherSitesCalledCount = 0
    var fetchSponsoredSitesCalledCount = 0
    var recalculateTopSitesCalled: () -> Void = {}

    var removeTopSiteCalledCount = 0
    var pinTopSiteCalledCount = 0
    var unpinTopSiteCalledCount = 0

    private let lock = NSLock()

    func getOtherSites() async -> [TopSiteConfiguration] {
        getOtherSitesCalledCount += 1
        return createSites(count: 15, subtitle: ": otherSites")
    }

    func fetchSponsoredSites() async -> [Site] {
        fetchSponsoredSitesCalledCount += 1

        let contiles = MockSponsoredProvider.defaultSuccessData
        return contiles.compactMap { Site.createSponsoredSite(fromContile: $0) }
    }

    func recalculateTopSites(otherSites: [TopSiteConfiguration], sponsoredSites: [Site]) -> [TopSiteConfiguration] {
        // We add this completion since this method is called in an asynchronous
        recalculateTopSitesCalled()
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
