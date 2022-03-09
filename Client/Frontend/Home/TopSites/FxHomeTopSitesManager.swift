// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

class FxHomeTopSitesManager {

    private let topSiteHistoryManager: TopSiteHistoryManager
    private let profile: Profile
    var content: [Site] = []
    
    init(profile: Profile) {
        self.profile = profile
        self.topSiteHistoryManager = TopSiteHistoryManager(profile: profile)
    }

    func removePinTopSite(site: Site) {
        // Special Case: Hide google top site
        if site.guid == GoogleTopSiteManager.Constants.googleGUID {
            let gTopSite = GoogleTopSiteManager(prefs: profile.prefs)
            gTopSite.isHidden = true
        }

        // TODO: Laurie - .main needed?
        profile.history.removeFromPinnedTopSites(site).uponQueue(.main) { [weak self] result in
            guard result.isSuccess, let self = self else { return }
            self.refreshIfNeeded(forceTopSites: true)
        }
    }

    func refreshIfNeeded(forceTopSites: Bool) {
        topSiteHistoryManager.refreshIfNeeded(forceTopSites: forceTopSites)
    }

    // Reloads both highlights and top sites data from their respective caches. Does not invalidate the cache.
    // See TopSiteHistoryManager for invalidation logic.
    func loadTopSitesData() {

        TopSitesHelper.getTopSites(profile: profile).uponQueue(.main) { [weak self] result in
            guard let self = self else { return }

            let numRows = max(self.profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows) ?? TopSitesRowCountSettingsController.defaultNumberOfRows, 1)
            var sites = Array(result)

            // Check if all result items are pinned site
            var pinnedSites = 0
            result.forEach {
                if let _ = $0 as? PinnedSite {
                    pinnedSites += 1
                }
            }
            // TODO: Laurie - refactor logic for Google top site
//            // Special case: Adding Google topsite
//            let googleTopSite = GoogleTopSiteManager(prefs: self.profile.prefs)
//            if !googleTopSite.isHidden, let gSite = googleTopSite.suggestedSiteData() {
//                // Once Google top site is added, we don't remove unless it's explicitly unpinned
//                // Add it when pinned websites are less than max pinned sites
//                if googleTopSite.hasAdded || pinnedSites < maxItems {
//                    sites.insert(gSite, at: 0)
//                    // Purge unwanted websites from the end of list
//                    if sites.count > maxItems {
//                        sites.removeLast(sites.count - maxItems)
//                    }
//                    googleTopSite.hasAdded = true
//                }
//            }

            self.content = sites

            // Refresh the AS data in the background so we'll have fresh data next time we show.
            self.refreshIfNeeded(forceTopSites: false)
        }
    }
}

extension FxHomeTopSitesManager: DataObserverDelegate {

    // Invoked by the TopSiteHistoryManager when highlights/top sites invalidation is complete.
    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool) {
        // Do not reload panel unless we're currently showing the highlight intro or if we
        // force-reloaded the highlights or top sites. This should prevent reloading the
        // panel after we've invalidated in the background on the first load.
        if forced {
            // TODO: Laurie - delegate call
//            reloadAll()
        }
    }
}
