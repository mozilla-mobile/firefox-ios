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

    private let googleTopSiteManager: GoogleTopSiteManager
    private let profile: Profile
    private var topSites: [HomeTopSite] = []
    private var historySites: [Site] = []

    weak var delegate: FxHomeTopSitesManagerDelegate?
    lazy var topSiteHistoryManager = TopSiteHistoryManager(profile: profile)
    
    init(profile: Profile) {
        self.profile = profile
        self.googleTopSiteManager = GoogleTopSiteManager(prefs: profile.prefs)
        topSiteHistoryManager.delegate = self
    }

    func getSite(index: Int) -> HomeTopSite? {
        guard !topSites.isEmpty, index < topSites.count, index >= 0 else { return nil }
        return topSites[index]
    }

    func getSiteDetail(index: Int) -> Site? {
        guard !topSites.isEmpty, index < topSites.count, index >= 0 else { return nil }
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
    func loadTopSitesData(completion: (() -> Void)? = nil) {
        topSiteHistoryManager.getTopSites { sites in
            self.historySites = sites
            completion?()
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
        // TODO: When updating the top sites settings, investigate if topsites can be 0. From current settings
        // it can be a minimum of 1.
        return Int(max(preferredNumberOfRows ?? defaultNumberOfRows, 1))
    }

    private func countPinnedSites(sites: [Site]) -> Int {
        var pinnedSites = 0
        sites.forEach {
            if let _ = $0 as? PinnedSite { pinnedSites += 1 }
        }
        return pinnedSites
    }
}

extension FxHomeTopSitesManager: DataObserverDelegate {

    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool) {
        guard forced else { return }
        delegate?.reloadTopSites()
    }
}
