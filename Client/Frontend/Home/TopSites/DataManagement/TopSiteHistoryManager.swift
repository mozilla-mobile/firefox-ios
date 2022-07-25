// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage

// Manages the top site
class TopSiteHistoryManager: DataObserver, Loggable {

    let profile: Profile

    weak var delegate: DataObserverDelegate?
    var notificationCenter = NotificationCenter.default

    private let topSiteCacheSize: Int32 = 32
    private let events: [Notification.Name] = [.FirefoxAccountChanged, .ProfileDidFinishSyncing, .PrivateDataClearedHistory]
    private let dataQueue = DispatchQueue(label: "com.moz.topSiteHistory.queue")

    lazy var topSitesProvider: TopSitesProvider = TopSitesProviderImplementation(browserHistoryFetcher: profile.history,
                                                                                 prefs: profile.prefs)

    init(profile: Profile) {
        self.profile = profile
        profile.history.setTopSitesCacheSize(topSiteCacheSize)

        setupNotifications(forObserver: self, observing: events)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    /// RefreshIfNeeded will refresh the underlying caches for TopSites.
    /// By default this will only refresh topSites if KeyTopSitesCacheIsValid is false
    /// - Parameter forceTopSites: Refresh can be forced by setting this to true
    func refreshIfNeeded(forceTopSites: Bool) {
        guard !profile.isShutdown else { return }

        // KeyTopSitesCacheIsValid is false when we want to invalidate. Thats why this logic is so backwards
        let shouldInvalidateTopSites = forceTopSites || !(profile.prefs.boolForKey(PrefsKeys.KeyTopSitesCacheIsValid) ?? false)
        guard shouldInvalidateTopSites else { return }

        // Flip the `KeyTopSitesCacheIsValid` flag now to prevent subsequent calls to refresh
        // from re-invalidating the cache.
        profile.prefs.setBool(true, forKey: PrefsKeys.KeyTopSitesCacheIsValid)

        delegate?.willInvalidateDataSources(forceTopSites: forceTopSites)
        profile.recommendations.repopulate(invalidateTopSites: shouldInvalidateTopSites).uponQueue(dataQueue) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.didInvalidateDataSources(refresh: forceTopSites, topSitesRefreshed: shouldInvalidateTopSites)
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
            self.refreshIfNeeded(forceTopSites: true)
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

// MARK: - Notifiable protocol
extension TopSiteHistoryManager: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .ProfileDidFinishSyncing, .FirefoxAccountChanged, .PrivateDataClearedHistory:
            refreshIfNeeded(forceTopSites: true)
        default:
            browserLog.warning("Received unexpected notification \(notification.name)")
        }
    }
}
