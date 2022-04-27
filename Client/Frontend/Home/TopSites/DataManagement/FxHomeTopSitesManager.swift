// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

protocol FxHomeTopSitesManagerDelegate: AnyObject {
    func reloadTopSites()
}

class FxHomeTopSitesManager: FeatureFlagsProtocol {

    private let profile: Profile
    private var topSites: [HomeTopSite] = []
    private let dataQueue = DispatchQueue(label: "com.moz.topSitesManager.queue", qos: .userInteractive)

    // Raw data to build top sites with
    private var historySites: [Site] = []
    private var contiles: [Contile] = []

    weak var delegate: FxHomeTopSitesManagerDelegate?
    lazy var topSiteHistoryManager = TopSiteHistoryManager(profile: profile)
    lazy var googleTopSiteManager = GoogleTopSiteManager(prefs: profile.prefs)
    lazy var contileProvider: ContileProviderInterface = ContileProvider()

    init(profile: Profile) {
        self.profile = profile
        topSiteHistoryManager.delegate = self
    }

    func getSite(index: Int) -> HomeTopSite? {
        guard let topSite = topSites[safe: index] else { return nil }
        return topSite
    }

    func getSiteDetail(index: Int) -> Site? {
        guard let siteDetail = topSites[safe: index]?.site else { return nil }
        return siteDetail
    }

    var hasData: Bool {
        return !historySites.isEmpty
    }

    var siteCount: Int {
        return topSites.count
    }

    func removePinTopSite(site: Site) {
        googleTopSiteManager.removeGoogleTopSite(site: site)
        topSiteHistoryManager.removeTopSite(site: site)
    }

    func refreshIfNeeded(forceTopSites: Bool) {
        topSiteHistoryManager.refreshIfNeeded(forceTopSites: forceTopSites)
    }

    // MARK: - Data loading

    // Loads the data source of top sites
    func loadTopSitesData(dataLoadingCompletion: (() -> Void)? = nil) {
        let group = DispatchGroup()
        loadContiles(group: group)
        loadTopSites(group: group)

        group.notify(queue: dataQueue) {
            // Pre-loading the data with a default number of tiles so we always show section when needed
            self.calculateTopSiteData(numberOfTilesPerRow: 8)

            dataLoadingCompletion?()
        }
    }

    private func loadContiles(group: DispatchGroup) {
        guard shouldLoadSponsoredTiles else { return }

        group.enter()
        contileProvider.fetchContiles { result in
            if case .success(let contiles) = result {
                self.contiles = contiles
            }
            group.leave()
        }
    }

    private func loadTopSites(group: DispatchGroup) {
        group.enter()
        topSiteHistoryManager.getTopSites { sites in
            self.historySites = sites
            group.leave()
        }
    }

    // MARK: - Tiles placement calculation

    /// Top sites are composed of pinned sites, history, Contiles and Google top site.
    /// Google top site is always first, then comes the contiles, pinned sites and history top sites.
    /// We only add Google top site or Contiles if number of pins doesn't exeeds the available number shown of tiles.
    /// - Parameter numberOfTilesPerRow: The number of tiles per row shown to the user
    func calculateTopSiteData(numberOfTilesPerRow: Int) {
        var sites = historySites
        let pinnedSiteCount = countPinnedSites(sites: sites)
        let totalNumberOfShownTiles = numberOfTilesPerRow * numberOfRows
        let availableSpacesCount = totalNumberOfShownTiles - pinnedSiteCount

        addSponsoredTiles(sites: &sites, availableSpacesCount: availableSpacesCount)
        addGoogleTopSite(sites: &sites, availableSpacesCount: availableSpacesCount)

        sites.removeDuplicates()

        topSites = sites.map { HomeTopSite(site: $0, profile: profile) }

        // Refresh data in the background so we'll have fresh data next time we show
        refreshIfNeeded(forceTopSites: false)
    }

    // The number of rows the user wants.
    // If there is no preference, the default is used.
    var numberOfRows: Int {
        let preferredNumberOfRows = profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows)
        let defaultNumberOfRows = TopSitesRowCountSettingsController.defaultNumberOfRows
        return Int(preferredNumberOfRows ?? defaultNumberOfRows)
    }

    private func addSponsoredTiles(sites: inout [Site], availableSpacesCount: Int) {
        guard shouldShowSponsoredTiles else { return }

        // Google tile has precedence over Sponsored Tiles
        let sponsoredTileSpaces = availableSpacesCount - GoogleTopSiteManager.Constants.reservedSpaceCount
        if sponsoredTileSpaces > 0 {
            sites.addSponsoredTiles(sponsoredTileSpaces: sponsoredTileSpaces, contiles: contiles)
        }
    }

    private func addGoogleTopSite(sites: inout [Site], availableSpacesCount: Int) {
        guard googleTopSiteManager.shouldAddGoogleTopSite(availableSpacesCount: availableSpacesCount) else { return }
        googleTopSiteManager.addGoogleTopSite(sites: &sites)
    }

    private func countPinnedSites(sites: [Site]) -> Int {
        var pinnedSites = 0
        sites.forEach {
            if let _ = $0 as? PinnedSite { pinnedSites += 1 }
        }
        return pinnedSites
    }

    // MARK: - Sponsored tiles (Contiles)

    static let maximumNumberOfSponsoredTile = 2

    // TODO: Check for settings user preference with https://mozilla-hub.atlassian.net/browse/FXIOS-3469
    // TODO: Check for nimbus with https://mozilla-hub.atlassian.net/browse/FXIOS-3468
    private var shouldLoadSponsoredTiles: Bool {
        return featureFlags.isFeatureActiveForBuild(.sponsoredTiles) && profile.prefs.boolForKey(PrefsKeys.KeyShowSponsoredShortcuts) ?? true
    }

    private var shouldShowSponsoredTiles: Bool {
        return !contiles.isEmpty && shouldLoadSponsoredTiles
    }
}

// MARK: Site Array extension
private extension Array where Element == Site {

    /// Add sponsored tiles to the top sites.
    /// - Parameters:
    ///   - sponsoredTileSpaces: The number of spaces available for sponsored tiles
    ///   - sites: The top sites to add the sponsored tile to
    mutating func addSponsoredTiles(sponsoredTileSpaces: Int, contiles: [Contile]) {
        var siteAdded = 0
        for (index, _) in contiles.enumerated() {

            guard siteAdded < sponsoredTileSpaces, let contile = contiles[safe: index] else { return }
            let site = SponsoredTile(contile: contile)

            // Show the next sponsored site if site is already present in the pinned sites
            guard !siteIsAlreadyPresent(site: site) else { continue }

            insert(site, at: 0)
            siteAdded += 1

            // Do not add more sponsored tile if we reach the maximum
            guard siteAdded < FxHomeTopSitesManager.maximumNumberOfSponsoredTile else { break }
        }
    }

    // Keeping the order of the sites, we remove duplicate tiles.
    // Ex: If a sponsored tile is present then it has precedence over the history sites.
    // Ex: A default site is present but user has recent history site of the same site. That recent history tile won't be added.
    mutating func removeDuplicates() {
        var alreadyThere = Set<Site>()
        let uniqueSites = compactMap { (site) -> Site? in
            let shouldAddSite = alreadyThere.first(where: { $0.url.asURL?.domainURL == site.url.asURL?.domainURL } ) == nil
            guard shouldAddSite else { return nil }
            alreadyThere.insert(site)
            return site
        }

        self = uniqueSites
    }

    // We don't add a sponsored tile if that domain site is already pinned by the user.
    private func siteIsAlreadyPresent(site: Site) -> Bool {
        return filter { ($0.url.asURL?.domainURL == site.url.asURL?.domainURL) && (($0 as? PinnedSite) != nil) }.count > 0
    }
}

// MARK: - DataObserverDelegate
extension FxHomeTopSitesManager: DataObserverDelegate {

    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool) {
        guard forced else { return }
        delegate?.reloadTopSites()
    }
}
