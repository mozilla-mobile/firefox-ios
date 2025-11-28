// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

protocol TopSiteHistoryManagerProvider: Sendable {
    func getTopSites(completion: @escaping @Sendable ([Site]?) -> Void)
    func removeDefaultTopSitesTile(site: Site)
    func remove(pinnedSite: Site) async throws
}

// Manages the top site
// FIXME: FXIOS-14053 Can't be `final` and `Sendable` unless tests are rewritten for `TopSiteHistoryManagerStub`
class TopSiteHistoryManager: TopSiteHistoryManagerProvider, @unchecked Sendable {
    private let profile: Profile

    private let topSiteCacheSize: Int32 = 32
    private let topSitesProvider: TopSitesProvider

    @MainActor
    init(profile: Profile) {
        self.profile = profile
        self.topSitesProvider = TopSitesProviderImplementation(
            placesFetcher: profile.places,
            pinnedSiteFetcher: profile.pinnedSites,
            prefs: profile.prefs
        )
    }

    func getTopSites(completion: @escaping @Sendable ([Site]?) -> Void) {
        topSitesProvider.getTopSites { [weak self] result in
            guard self != nil else { return }
            completion(result)
        }
    }

    func remove(pinnedSite: Site) async throws {
        try await profile.pinnedSites.remove(pinnedSite: pinnedSite)
    }

    // TODO: FXIOS-10245 Remove when we nuke legacy homepage from the codebase
    func removeTopSite(site: Site) {
        profile.pinnedSites.removeFromPinnedTopSites(site)
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
