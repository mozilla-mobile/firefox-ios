// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

// TODO: FXIOS-10165 - Add full logic + tests for retrieving top sites
/// Manager to fetch the top sites data, The data gets updated from notifications on specific user actions
class TopSitesManager {
    private var logger: Logger
    private let prefs: Prefs
    private let contileProvider: ContileProviderInterface
    private let googleTopSiteManager: GoogleTopSiteManagerProvider
    private let topSiteHistoryManager: TopSiteHistoryManagerProvider

    init(
        prefs: Prefs,
        contileProvider: ContileProviderInterface = ContileProvider(),
        googleTopSiteManager: GoogleTopSiteManagerProvider,
        topSiteHistoryManager: TopSiteHistoryManagerProvider,
        logger: Logger = DefaultLogger.shared
    ) {
        self.prefs = prefs
        self.contileProvider = contileProvider
        self.googleTopSiteManager = googleTopSiteManager
        self.topSiteHistoryManager = topSiteHistoryManager
        self.logger = logger
    }

    func getTopSites() async -> [TopSiteState] {
        var topSites: [TopSiteState] = []

        let googleTopSite = addGoogleTopSite()
        let sponsoredTopSites = await getSponsoredSites()
        let historyBasedTopSites = await getHistoryBasedSites()

        topSites = googleTopSite + sponsoredTopSites + historyBasedTopSites

        return topSites
    }

    private func addGoogleTopSite() -> [TopSiteState] {
        guard let googleSite = googleTopSiteManager.suggestedSiteData else {
            return []
        }
        return [TopSiteState(site: googleSite)]
    }

    // MARK: Sponsored tiles (Contiles)
    private var shouldLoadSponsoredTiles: Bool {
        return prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.SponsoredShortcuts) ?? true
    }

    private func getSponsoredSites() async -> [TopSiteState] {
        guard shouldLoadSponsoredTiles else { return [] }

        let contiles = await withCheckedContinuation { continuation in
            contileProvider.fetchContiles { [weak self] result in
                if case .success(let contiles) = result {
                    continuation.resume(returning: contiles)
                } else {
                    self?.logger.log(
                        "Contile provider did not return any sponsored tiles when requested",
                        level: .warning,
                        category: .homepage
                    )
                    continuation.resume(returning: [])
                }
            }
        }

        return contiles.compactMap {
            TopSiteState(site: SponsoredTile(contile: $0))
        }
    }

    // MARK: History-based (Frencency) + Pinned + Default suggested tiles
    private func getHistoryBasedSites() async -> [TopSiteState] {
        let frecencySites = await withCheckedContinuation { continuation in
            topSiteHistoryManager.getTopSites { sites in
                continuation.resume(returning: sites)
            }
        }

        return frecencySites?.compactMap { TopSiteState(site: $0) } ?? []
    }
}
