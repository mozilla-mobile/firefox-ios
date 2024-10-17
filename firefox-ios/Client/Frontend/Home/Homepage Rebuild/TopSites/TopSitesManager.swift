// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

class TopSitesManager {
    private let topSiteHistoryManager: TopSiteHistoryManager
    private let googleTopSiteManager: GoogleTopSiteManager

    init(
        topSiteHistoryManager: TopSiteHistoryManager,
        googleTopSiteManager: GoogleTopSiteManager
    ) {
        self.topSiteHistoryManager = topSiteHistoryManager
        self.googleTopSiteManager = googleTopSiteManager
    }

    func getTopSites() async -> [TopSite] {
        var sites = await getTopSiteItems()
        if let site = addGoogleTopSite() {
            sites.insert(site, at: 0)
        }
        return sites
    }

    private func getTopSiteItems() async -> [TopSite] {
        let topSites = await withCheckedContinuation { continuation in
            topSiteHistoryManager.getTopSites { result in
                let sites = result ?? []
                continuation.resume(returning: sites)
            }
        }

        return topSites.compactMap { TopSite(site: $0) }
    }

    private func addGoogleTopSite() -> TopSite? {
        guard let googleSite = googleTopSiteManager.suggestedSiteData else {
            return nil
        }
        return TopSite(site: googleSite)
    }
}
