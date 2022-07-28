// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage

// Manages the top site
class TopSiteHistoryManager: DataObserver, Loggable {

    private let profile: Profile

    weak var delegate: DataObserverDelegate?

    private let topSiteCacheSize: Int32 = 32
    private let dataQueue = DispatchQueue(label: "com.moz.topSiteHistory.queue")
    private let topSitesProvider: TopSitesProvider

    init(profile: Profile) {
        self.profile = profile
        self.topSitesProvider = TopSitesProviderImplementation(browserHistoryFetcher: profile.history,
                                                               prefs: profile.prefs)
        profile.history.setTopSitesCacheSize(topSiteCacheSize)
    }

    /// RefreshIfNeeded will refresh the underlying caches for TopSites.
    /// By default this will only refresh topSites if KeyTopSitesCacheIsValid is false
    /// - Parameter forced: Refresh can be forced by setting this to true
    func refreshIfNeeded(forceRefresh forced: Bool) {
        guard !profile.isShutdown else { return }

        // KeyTopSitesCacheIsValid is false when we want to invalidate. Thats why this logic is so backwards
        let shouldInvalidateTopSites = forced || !(profile.prefs.boolForKey(PrefsKeys.KeyTopSitesCacheIsValid) ?? false)
        guard shouldInvalidateTopSites else { return }

        // Flip the `KeyTopSitesCacheIsValid` flag now to prevent subsequent calls to refresh
        // from re-invalidating the cache.
        profile.prefs.setBool(true, forKey: PrefsKeys.KeyTopSitesCacheIsValid)

        profile.recommendations.repopulate(invalidateTopSites: shouldInvalidateTopSites).uponQueue(dataQueue) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didInvalidateDataSource(forceRefresh: forced)
        }
    }

    func getTopSites(completion: @escaping ([Site]?) -> Void) {
        topSitesProvider.getTopSites { [weak self] result in
            guard let _ = self else { return }
            completion(result)
        }
    }

    func removeTopSite(site: Site) {
        profile.history.removeFromPinnedTopSites(site).uponQueue(dataQueue) { [weak self] result in
            guard result.isSuccess, let self = self else { return }
            self.refreshIfNeeded(forceRefresh: true)
        }
    }

    /// If the default top sites contains the siteurl. also wipe it from default suggested sites.
    func removeDefaultTopSitesTile(site: Site) {
        let url = site.tileURL.absoluteString
        if topSitesProvider.defaultTopSites(profile.prefs).contains(where: { $0.url == url }) {
            deleteTileForSuggestedSite(url)
        }
    }

    private func deleteTileForSuggestedSite(_ siteURL: String) {
        var deletedSuggestedSites = profile.prefs.arrayForKey(topSitesProvider.defaultSuggestedSitesKey) as? [String] ?? []
        deletedSuggestedSites.append(siteURL)
        profile.prefs.setObject(deletedSuggestedSites, forKey: topSitesProvider.defaultSuggestedSitesKey)
    }
}
