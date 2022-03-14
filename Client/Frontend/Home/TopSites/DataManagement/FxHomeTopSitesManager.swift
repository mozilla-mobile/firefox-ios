// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

protocol FxHomeTopSitesManagerDelegate: AnyObject {
    func reloadTopSites()
}

class FxHomeTopSitesManager {

    private let maximumTileNumberPerRow = 12
    private let topSiteHistoryManager: TopSiteHistoryManager
    private let googleTopSiteManager: GoogleTopSiteManager
    private let profile: Profile

    private var topSites: [HomeTopSite] = []
    private var historySites: [Site] = []

    weak var delegate: FxHomeTopSitesManagerDelegate?
    
    init(profile: Profile) {
        self.profile = profile
        self.topSiteHistoryManager = TopSiteHistoryManager(profile: profile)
        self.googleTopSiteManager = GoogleTopSiteManager(prefs: profile.prefs)
        topSiteHistoryManager.delegate = self
    }

    func getSite(index: Int) -> HomeTopSite? {
        guard !topSites.isEmpty, index < topSites.count else { return nil }
        return topSites[index]
    }

    func getSiteDetail(index: Int) -> Site? {
        guard !topSites.isEmpty, index < topSites.count else { return nil }
        return topSites[index].site
    }

    var hasData: Bool {
        return !historySites.isEmpty
    }

    var siteCount: Int {
        return historySites.count
    }

    func removePinTopSite(site: Site) {
        googleTopSiteManager.removeGoogleTopSite(site: site)
        topSiteHistoryManager.removeTopSite(site: site)
    }

    func refreshIfNeeded(forceTopSites: Bool) {
        topSiteHistoryManager.refreshIfNeeded(forceTopSites: forceTopSites)
    }

    // Loads the data source of top sites
    func loadTopSitesData() {
        topSiteHistoryManager.getTopSites { sites in
            self.historySites = sites
        }
    }

    // Top sites are composed of pinned sites, history and Google top site
    func calculateTopSiteData(numberOfTilesPerRow: Int) {
        var sites = historySites
        let pinnedSiteCount = countPinnedSites(sites: sites)
        let maxItems = numberOfTilesPerRow * numberOfRows

        if googleTopSiteManager.shouldAddGoogleTopSite(pinnedSiteCount: pinnedSiteCount,
                                                       maxItems: maxItems) {
            googleTopSiteManager.addGoogleTopSite(maxItems: maxItems, sites: &sites)
        }

        topSites = sites.map { HomeTopSite(site: $0, profile: profile) }

        // Refresh data in the background so we'll have fresh data next time we show
        refreshIfNeeded(forceTopSites: false)
    }

    // The number of rows the user wants.
    // If there is no preference, the default is used.
    var numberOfRows: Int {
        let preferredNumberOfRows = profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows)
        let defaultNumberOfRows = TopSitesRowCountSettingsController.defaultNumberOfRows
        return Int(max(preferredNumberOfRows ?? defaultNumberOfRows, 1))
    }

    private func countPinnedSites(sites: [Site]) -> Int {
        var pinnedSites = 0
        sites.forEach {
            if let _ = $0 as? PinnedSite {
                pinnedSites += 1
            }
        }
        return pinnedSites
    }
}

extension FxHomeTopSitesManager: DataObserverDelegate {

    // Invoked by the TopSiteHistoryManager when highlights/top sites invalidation is complete.
    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool) {
        // Do not reload panel unless we're currently showing the highlight intro or if we
        // force-reloaded the highlights or top sites. This should prevent reloading the
        // panel after we've invalidated in the background on the first load.
        if forced {
            delegate?.reloadTopSites()
        }
    }
}
