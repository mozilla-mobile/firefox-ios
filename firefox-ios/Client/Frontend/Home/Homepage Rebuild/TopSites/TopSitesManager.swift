// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

// TODO: FXIOS-10165 - Add full logic + tests for retrieving top sites
/// Manager to fetch the top sites data, the data gets updated from notifications on specific user actions
class TopSitesManager {
    private var logger: Logger
    private let prefs: Prefs
    private let contileProvider: ContileProviderInterface
    private let googleTopSiteManager: GoogleTopSiteManagerProvider
    private let topSiteHistoryManager: TopSiteHistoryManagerProvider
    private let searchEnginesManager: SearchEnginesManagerProvider

    // TODO: FXIOS-10477 - Add number of rows calculation and device size updates
    private let maxTopSites: Int
    private let maxNumberOfSponsoredTile: Int = 2

    init(
        prefs: Prefs,
        contileProvider: ContileProviderInterface = ContileProvider(),
        googleTopSiteManager: GoogleTopSiteManagerProvider,
        topSiteHistoryManager: TopSiteHistoryManagerProvider,
        searchEnginesManager: SearchEnginesManagerProvider,
        logger: Logger = DefaultLogger.shared,
        maxTopSites: Int = 4 * 14 // Max rows * max tiles on the largest screen plus some padding
    ) {
        self.prefs = prefs
        self.contileProvider = contileProvider
        self.googleTopSiteManager = googleTopSiteManager
        self.topSiteHistoryManager = topSiteHistoryManager
        self.searchEnginesManager = searchEnginesManager
        self.logger = logger
        self.maxTopSites = maxTopSites
    }

    func getTopSites() async -> [TopSiteState] {
        return await calculateTopSites()
    }

    /// Top sites are composed of pinned sites, history, sponsored tiles and google top site.
    /// In terms of space, pinned tiles has precedence over the Google tile, 
    /// which has precedence over sponsored and frecency tiles.
    ///
    /// From a user perspective, Google top site is always first (from left to right),
    /// then comes the sponsored tiles, pinned sites and then frecency top sites.
    /// We only add Google or sponsored tiles if number of pinned tiles doesn't exceeds the available number shown of tiles.
    private func calculateTopSites() async -> [TopSiteState] {
        // TODO: FXIOS-10477 - Look into creating task groups to run asynchronous methods concurrently
        let otherSites = await getOtherSites()

        let availableSpaceCount = getAvailableSpaceCount(with: otherSites)
        let googleTopSite = addGoogleTopSite(with: availableSpaceCount)

        let updatedSpaceCount = getUpdatedSpaceCount(with: googleTopSite, and: availableSpaceCount)
        let sponsoredSites = await getSponsoredSites(with: updatedSpaceCount, and: otherSites)

        let totalTopSites = googleTopSite + sponsoredSites + otherSites

        let uniqueSites = removeDuplicates(for: totalTopSites)
        return Array(uniqueSites.prefix(maxTopSites))
    }

    // MARK: Google tile
    private func addGoogleTopSite(with availableSpaceCount: Int) -> [TopSiteState] {
        guard googleTopSiteManager.shouldAddGoogleTopSite(hasSpace: availableSpaceCount > 0),
                let googleSite = googleTopSiteManager.suggestedSiteData
        else {
            return []
        }
        return [TopSiteState(site: googleSite)]
    }

    // MARK: Sponsored tiles (Contiles)
    private var shouldLoadSponsoredTiles: Bool {
        return prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.SponsoredShortcuts) ?? true
    }

    private func getSponsoredSites(with availableSpaceCount: Int, and otherSites: [TopSiteState]) async -> [TopSiteState] {
        guard availableSpaceCount > 0, shouldLoadSponsoredTiles else { return [] }

        let contiles = await fetchSponsoredSites()

        guard !contiles.isEmpty else { return [] }

        let filteredContiles = contiles
            .filter { shouldShowSponsoredSite(with: $0, and: otherSites) }
            .compactMap { TopSiteState(site: $0) }

        return filteredContiles
    }

    private func fetchSponsoredSites() async -> [SponsoredTile] {
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

        return contiles
            .prefix(maxNumberOfSponsoredTile)
            .compactMap { SponsoredTile(contile: $0) }
    }

    /// Show the sponsored site only if site is not already present in the pinned sites 
    /// and it's not the default search engine
    private func shouldShowSponsoredSite(with sponsoredSite: Site, and otherSites: [TopSiteState]) -> Bool {
        let siteDomain = sponsoredSite.url.asURL?.shortDomain
        let sponsoredSiteIsAlreadyPresent = otherSites.contains {
            ($0.site.url.asURL?.shortDomain == siteDomain) && (($0.site as? PinnedSite) != nil)
        }

        let shouldAddDefaultEngine = SponsoredTileDataUtility().shouldAdd(
            site: sponsoredSite,
            with: searchEnginesManager.defaultEngine
        )

        return !sponsoredSiteIsAlreadyPresent && shouldAddDefaultEngine
    }

    // MARK: Other Sites = History-based (Frencency) + Pinned + Default suggested tiles
    private func getOtherSites() async -> [TopSiteState] {
        let otherSites = await withCheckedContinuation { continuation in
            topSiteHistoryManager.getTopSites { sites in
                continuation.resume(returning: sites)
            }
        }

        return otherSites?.compactMap { TopSiteState(site: $0) } ?? []
    }

    // MARK: - Tiles space calculation

    /// Get available space count for the sponsored tiles and Google tiles, pinned tiles are prioritized first
    /// - Parameter otherSites: Comes from fetching the other top sites that are not sponsored or google tile
    /// - Returns: The available space count for the rest of the calculation
    private func getAvailableSpaceCount(with otherSites: [TopSiteState]) -> Int {
        let pinnedSiteCount = otherSites.filter { $0.site is PinnedSite }.count
        return maxTopSites - pinnedSiteCount
    }

    private func getUpdatedSpaceCount(with googleTopSite: [TopSiteState], and availableSpaceCount: Int) -> Int {
        guard !googleTopSite.isEmpty else { return availableSpaceCount }
        return availableSpaceCount - GoogleTopSiteManager.Constants.reservedSpaceCount
    }

    // Keeping the order of the sites, we remove duplicate tiles.
    // Ex: If a sponsored tile is present then it has precedence over the history sites.
    // Ex: A default site is present but user has recent history site of the same site.
    // That recent history tile won't be added.
    private func removeDuplicates(for sites: [TopSiteState]) -> [TopSiteState] {
        var duplicates = Set<TopSiteState>()
        return sites.compactMap { (state) -> TopSiteState? in
            // Do not remove sponsored tiles or pinned tiles duplicates
            guard (state.site as? SponsoredTile) == nil && (state.site as? PinnedSite) == nil else {
                duplicates.insert(state)
                return state
            }

            let siteDomain = state.site.url.asURL?.shortDomain
            let shouldAddSite = !duplicates.contains(where: { $0.site.url.asURL?.shortDomain == siteDomain })

            // If shouldAddSite or site domain was not found, then insert the site
            guard shouldAddSite || siteDomain == nil else { return nil }
            duplicates.insert(state)

            return state
        }
    }
}
