// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

protocol TopSiteHistoryManagerProvider {
    func getTopSites(completion: @escaping ([Site]?) -> Void)
}

// Manages the top site
class TopSiteHistoryManager: DataObserver, TopSiteHistoryManagerProvider {
    private let profile: Profile

    weak var delegate: DataObserverDelegate?

    private let topSiteCacheSize: Int32 = 32
    private let topSitesProvider: TopSitesProvider

    init(profile: Profile) {
        self.profile = profile
        self.topSitesProvider = TopSitesProviderImplementation(
            placesFetcher: profile.places,
            pinnedSiteFetcher: profile.pinnedSites,
            prefs: profile.prefs
        )
    }

    func getTopSites(completion: @escaping ([Site]?) -> Void) {
        topSitesProvider.getTopSites { [weak self] result in
            guard self != nil else { return }
            completion(result)
        }
    }

    func removeTopSite(site: Site) {
        _ = profile.pinnedSites.removeFromPinnedTopSites(site)
    }

    /// If the default top sites contains the siteurl. also wipe it from default suggested sites.
    func removeDefaultTopSitesTile(site: Site) {
        let url = site.tileURL.absoluteString
        if topSitesProvider.defaultTopSites(profile.prefs).contains(where: { $0.url == url }) {
            deleteTileForSuggestedSite(url)
        }
    }

    private func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(
            topSitesProvider.defaultSuggestedSitesKey
        ) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: topSitesProvider.defaultSuggestedSitesKey)
    }
}
