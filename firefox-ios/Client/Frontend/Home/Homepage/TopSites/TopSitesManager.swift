// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import Storage

protocol TopSitesManagerInterface: Sendable {
    /// Returns a list of top sites state using the top site history manager to fetch the other sites
    /// which is composed of history-based (Frecency) + pinned + default suggested tiles
    func getOtherSites() async -> [TopSiteConfiguration]

    /// Returns a list of sponsored tiles using the `UnifiedAdsProvider`
    func fetchSponsoredSites() async -> [Site]

    /// Returns a list of top sites used to show the user
    ///
    /// Top sites are composed of pinned sites, history, sponsored tiles and google top site.
    /// In terms of space, pinned tiles has precedence over the Google tile,
    /// which has precedence over sponsored and frecency tiles.
    ///
    /// From a user perspective, Google top site is always first (from left to right),
    /// then comes the sponsored tiles, pinned sites and then frecency top sites.
    /// We only add Google or sponsored tiles if number of pinned tiles doesn't exceed the available number shown of tiles.
    ///
    /// - Parameters:
    ///   - otherSites: Contains the user's pinned sites, history, and default suggested sites.
    ///   - sponsoredSites: Contains the sponsored sites.
    @MainActor
    func recalculateTopSites(otherSites: [TopSiteConfiguration], sponsoredSites: [Site]) -> [TopSiteConfiguration]

    /// Removes the site out of the top sites.
    /// If site is pinned it removes it from pinned and top sites list.
    func removeTopSite(_ site: Site) async

    /// Adds the top site as a pinned tile in the top sites lists.
    func pinTopSite(_ site: Site)

    /// Unpin removes the top site from the location it's in.
    /// The site still can appear in the top sites as unpin.
    func unpinTopSite(_ site: Site) async
}

/// Manager to fetch the top sites data, the data gets updated from notifications on specific user actions
final class TopSitesManager: TopSitesManagerInterface, FeatureFlaggable {
    private let logger: Logger
    private let profile: Profile
    private let googleTopSiteManager: GoogleTopSiteManagerProvider
    private let topSiteHistoryManager: TopSiteHistoryManagerProvider
    private let searchEnginesManager: SearchEnginesManagerProvider
    private let unifiedAdsProvider: UnifiedAdsProviderInterface
    private let notification: NotificationProtocol

    private let maxTopSites: Int
    private let maxNumberOfSponsoredTile = 2

    init(
        profile: Profile,
        unifiedAdsProvider: UnifiedAdsProviderInterface = UnifiedAdsProvider(),
        googleTopSiteManager: GoogleTopSiteManagerProvider,
        topSiteHistoryManager: TopSiteHistoryManagerProvider,
        searchEnginesManager: SearchEnginesManagerProvider,
        logger: Logger = DefaultLogger.shared,
        notification: NotificationProtocol = NotificationCenter.default,
        maxTopSites: Int = 4 * 14 // Max rows * max tiles on the largest screen plus some padding
    ) {
        self.profile = profile
        self.unifiedAdsProvider = unifiedAdsProvider
        self.googleTopSiteManager = googleTopSiteManager
        self.topSiteHistoryManager = topSiteHistoryManager
        self.searchEnginesManager = searchEnginesManager
        self.logger = logger
        self.notification = notification
        self.maxTopSites = maxTopSites
    }

    @MainActor
    func recalculateTopSites(otherSites: [TopSiteConfiguration], sponsoredSites: [Site]) -> [TopSiteConfiguration] {
        let availableSpaceCount = getAvailableSpaceCount(with: otherSites)
        let googleTopSite = addGoogleTopSite(with: availableSpaceCount)

        let updatedSpaceCount = getUpdatedSpaceCount(with: googleTopSite, and: availableSpaceCount)
        let sponsoredSites = filterSponsoredSites(unifiedTiles: sponsoredSites, with: updatedSpaceCount, and: otherSites)

        let totalTopSites = googleTopSite + sponsoredSites + otherSites

        let uniqueSites = removeDuplicates(for: totalTopSites)
        return Array(uniqueSites.prefix(maxTopSites))
    }

    // MARK: Google tile
    private func addGoogleTopSite(with availableSpaceCount: Int) -> [TopSiteConfiguration] {
        guard googleTopSiteManager.shouldAddGoogleTopSite(hasSpace: availableSpaceCount > 0),
              let googleSite = googleTopSiteManager.pinnedSiteData
        else {
            return []
        }
        return [TopSiteConfiguration(site: googleSite)]
    }

    // MARK: Sponsored tiles (Unified Tiles)
    func fetchSponsoredSites() async -> [Site] {
        guard shouldLoadSponsoredTiles else { return [] }
        let unifiedTiles = await withCheckedContinuation { continuation in
            unifiedAdsProvider.fetchTiles { [weak self] result in
                if case .success(let unifiedTiles) = result {
                    continuation.resume(returning: unifiedTiles)
                } else {
                    self?.logger.log(
                        "Unified ads provider did not return any sponsored tiles when requested",
                        level: .warning,
                        category: .homepage
                    )
                    continuation.resume(returning: [])
                }
            }
        }

        return unifiedTiles.compactMap { Site.createSponsoredSite(fromUnifiedTile: $0) }
    }

    private var shouldLoadSponsoredTiles: Bool {
        return featureFlags.isFeatureEnabled(.hntSponsoredShortcuts, checking: .userOnly)
    }

    @MainActor
    private func filterSponsoredSites(
        unifiedTiles: [Site],
        with availableSpaceCount: Int,
        and otherSites: [TopSiteConfiguration]
    ) -> [TopSiteConfiguration] {
        guard availableSpaceCount > 0, shouldLoadSponsoredTiles else { return [] }

        guard !unifiedTiles.isEmpty else { return [] }

        let filteredTiles = unifiedTiles
            .prefix(maxNumberOfSponsoredTile)
            .filter { shouldShowSponsoredSite(with: $0, and: otherSites) }
            .compactMap { TopSiteConfiguration(site: $0) }

        return filteredTiles
    }

    /// Show the sponsored site only if site is not already present in the pinned sites
    /// and it's not the default search engine
    @MainActor
    private func shouldShowSponsoredSite(with sponsoredSite: Site, and otherSites: [TopSiteConfiguration]) -> Bool {
        let siteDomain = sponsoredSite.url.asURL?.shortDomain
        let sponsoredSiteIsAlreadyPresent = otherSites.contains { (topSite: TopSiteConfiguration) in
            (topSite.shortDomain == siteDomain) && (topSite.isPinned)
        }

        let shouldAddDefaultEngine = SponsoredTileDataUtility().shouldAdd(
            site: sponsoredSite,
            with: searchEnginesManager.defaultEngine
        )

        return !sponsoredSiteIsAlreadyPresent && shouldAddDefaultEngine
    }

    // MARK: Other Sites
    func getOtherSites() async -> [TopSiteConfiguration] {
        let otherSites = await withCheckedContinuation { continuation in
            topSiteHistoryManager.getTopSites { sites in
                continuation.resume(returning: sites)
            }
        }

        return otherSites?.compactMap { TopSiteConfiguration(site: $0) } ?? []
    }

    // MARK: - Tiles space calculation

    /// Get available space count for the sponsored tiles and Google tiles, pinned tiles are prioritized first
    /// - Parameter otherSites: Comes from fetching the other top sites that are not sponsored or google tile
    /// - Returns: The available space count for the rest of the calculation
    private func getAvailableSpaceCount(with otherSites: [TopSiteConfiguration]) -> Int {
        let pinnedSiteCount = otherSites.filter { $0.isPinned }.count
        return maxTopSites - pinnedSiteCount
    }

    private func getUpdatedSpaceCount(with googleTopSite: [TopSiteConfiguration], and availableSpaceCount: Int) -> Int {
        guard !googleTopSite.isEmpty else { return availableSpaceCount }
        return availableSpaceCount - GoogleTopSiteManager.Constants.reservedSpaceCount
    }

    // Keeping the order of the sites, we remove duplicate tiles.
    // Ex: If a sponsored tile is present then it has precedence over the history sites.
    // Ex: A default site is present but user has recent history site of the same site.
    // That recent history tile won't be added.
    private func removeDuplicates(for sites: [TopSiteConfiguration]) -> [TopSiteConfiguration] {
        var previousStates = Set<TopSiteConfiguration>()
        return sites.compactMap { (state) -> TopSiteConfiguration? in
            // Do not remove sponsored tiles or pinned tiles duplicates
            guard !state.isSponsored, !state.isPinned else {
                previousStates.insert(state)
                return state
            }

            let siteDomain = state.shortDomain
            let shouldAddSite = !previousStates.contains(where: { $0.shortDomain == siteDomain })

            // If shouldAddSite or site domain was not found, then insert the site
            guard shouldAddSite || siteDomain == nil else { return nil }
            previousStates.insert(state)

            return state
        }
    }

    // MARK: - Context menu actions
    func removeTopSite(_ site: Site) async {
        googleTopSiteManager.removeGoogleTopSite(site: site)
        do {
            try await topSiteHistoryManager.remove(pinnedSite: site)
            hideURLFromTopSites(site)
        } catch {
            logger.log(
                "Removing pinned site threw an error - \(error.localizedDescription)",
                level: .warning,
                category: .homepage
            )
        }
    }

    func pinTopSite(_ site: Site) {
        profile.pinnedSites.addPinnedTopSite(site)
    }

    func unpinTopSite(_ site: Site) async {
        googleTopSiteManager.removeGoogleTopSite(site: site)
        try? await topSiteHistoryManager.remove(pinnedSite: site)
    }

    private func hideURLFromTopSites(_ site: Site) {
        topSiteHistoryManager.removeDefaultTopSitesTile(site: site)
        // We make sure to remove all history for URL so it doesn't show anymore in the
        // top sites, this is the approach that Android takes too.
        profile.places.deleteVisitsFor(url: site.url).uponQueue(.main) { [weak self] _ in
            self?.notification.post(name: .TopSitesUpdated, withObject: nil)
        }
    }
}
