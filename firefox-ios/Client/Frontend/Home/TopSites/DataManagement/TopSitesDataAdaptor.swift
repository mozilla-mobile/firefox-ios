// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage
import Common

protocol TopSitesManagerDelegate: AnyObject {
    func didLoadNewData()
}

/// Data adaptor to fetch the top sites data asynchronously
/// The data gets updated from notifications on specific user actions
protocol TopSitesDataAdaptor {
    /// The preferred number of rows by the user, this can be from 1 to 4
    /// Note that this isn't necessarily the number of rows that will appear since empty rows won't show.
    /// In other words, the number of rows shown depends on the actual data and the user preference.
    var numberOfRows: Int { get }

    /// Get top sites data
    func getTopSitesData() -> [TopSite]
}

class TopSitesDataAdaptorImplementation: TopSitesDataAdaptor, FeatureFlaggable {
    private let profile: Profile
    private var topSites: [TopSite] = []
    private let dataQueue = DispatchQueue(label: "com.moz.topSitesManager.queue")

    // Raw data to build top sites with
    private var historySites: [Site] = []
    private var contiles: [Contile] = []

    private let maxTopSites = 4 * 14 // Max rows * max tiles on the largest screen plus some padding
    var notificationCenter: NotificationProtocol
    weak var delegate: TopSitesManagerDelegate?
    private let topSiteHistoryManager: TopSiteHistoryManager
    private let googleTopSiteManager: GoogleTopSiteManager
    private let contileProvider: ContileProviderInterface
    private let dispatchGroup: DispatchGroupInterface

    // Pre-loading the data with a default number of tiles so we always show section when needed
    // If this isn't done, then no data will be found from the view model and section won't show
    // This gets adjusted once we actually know in which UI we're showing top sites.
    private static let defaultTopSitesRowCount = 8

    init(profile: Profile,
         topSiteHistoryManager: TopSiteHistoryManager,
         googleTopSiteManager: GoogleTopSiteManager,
         contileProvider: ContileProviderInterface = ContileProvider(),
         notificationCenter: NotificationProtocol = NotificationCenter.default,
         dispatchGroup: DispatchGroupInterface = DispatchGroup()
    ) {
        self.profile = profile
        self.topSiteHistoryManager = topSiteHistoryManager
        self.googleTopSiteManager = googleTopSiteManager
        self.contileProvider = contileProvider
        self.notificationCenter = notificationCenter
        self.dispatchGroup = dispatchGroup
        topSiteHistoryManager.delegate = self

        setupNotifications(forObserver: self,
                           observing: [.FirefoxAccountChanged,
                                       .PrivateDataClearedHistory,
                                       .ProfileDidFinishSyncing,
                                       .TopSitesUpdated,
                                       .DefaultSearchEngineUpdated])

        loadTopSitesData()
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    func getTopSitesData() -> [TopSite] {
        recalculateTopSiteData()
        return topSites
    }

    /// Calculate top site data
    /// This calculation is dependent on the number of tiles per row that is shown in the user interface.
    /// Top sites are composed of pinned sites, history, Contiles and Google top site.
    /// Google top site is always first, then comes the contiles, pinned sites and history top sites.
    /// We only add Google top site or Contiles if number of pins doesn't exceeds the available number shown of tiles.
    private func recalculateTopSiteData() {
        var sites = historySites
        let availableSpaceCount = getAvailableSpaceCount(maxTopSites: maxTopSites)
        let shouldAddGoogle = shouldAddGoogle(availableSpaceCount: availableSpaceCount)

        // Add Sponsored tile
        if shouldAddSponsoredTiles {
            addSponsoredTiles(sites: &sites,
                              shouldAddGoogle: shouldAddGoogle,
                              availableSpaceCount: availableSpaceCount)
        }

        // Add Google Tile
        if shouldAddGoogle {
            addGoogleTopSite(sites: &sites)
        }

        sites.removeDuplicates()

        topSites = sites.map { TopSite(site: $0) }
    }

    // MARK: - Data loading

    // Loads the data source of top sites. Internal for convenience of testing
    func loadTopSitesData(dataLoadingCompletion: (() -> Void)? = nil) {
        loadContiles()
        loadTopSites()

        dispatchGroup.notify(queue: dataQueue) { [weak self] in
            self?.recalculateTopSiteData()
            self?.delegate?.didLoadNewData()
            dataLoadingCompletion?()
        }
    }

    private func loadContiles() {
        guard shouldLoadSponsoredTiles else { return }

        dispatchGroup.enter()
        contileProvider.fetchContiles { [weak self] result in
            if case .success(let contiles) = result {
                self?.contiles = contiles
            } else {
                self?.contiles = []
            }
            self?.dispatchGroup.leave()
        }
    }

    private func loadTopSites() {
        dispatchGroup.enter()

        topSiteHistoryManager.getTopSites { [weak self] sites in
            if let sites = sites {
                self?.historySites = sites
            }
            self?.dispatchGroup.leave()
        }
    }

    // MARK: - Tiles placement calculation

    /// Get available space count for the sponsored tiles and Google tiles
    /// - Parameter numberOfTilesPerRow: Comes from top sites view model and accounts for different
    ///                                  layout (landscape, portrait, iPhone, iPad, etc).
    /// - Returns: The available space count for the rest of the calculation
    private func getAvailableSpaceCount(maxTopSites: Int) -> Int {
        let pinnedSiteCount = countPinnedSites(sites: historySites)
        return maxTopSites - pinnedSiteCount
    }

    // The number of rows the user wants.
    // If there is no preference, the default is used.
    var numberOfRows: Int {
        let preferredNumberOfRows = profile.prefs.intForKey(PrefsKeys.NumberOfTopSiteRows)
        let defaultNumberOfRows = TopSitesRowCountSettingsController.defaultNumberOfRows
        return Int(preferredNumberOfRows ?? defaultNumberOfRows)
    }

    func addSponsoredTiles(sites: inout [Site],
                           shouldAddGoogle: Bool,
                           availableSpaceCount: Int) {
        let sponsoredTileSpaces = getSponsoredNumberTiles(shouldAddGoogle: shouldAddGoogle,
                                                          availableSpaceCount: availableSpaceCount)

        if sponsoredTileSpaces > 0 {
            sites.addSponsoredTiles(sponsoredTileSpaces: sponsoredTileSpaces,
                                    contiles: contiles,
                                    defaultSearchEngine: profile.searchEnginesManager.defaultEngine)
        }
    }

    private func countPinnedSites(sites: [Site]) -> Int {
        var pinnedSites = 0
        sites.forEach {
            if $0 as? PinnedSite != nil { pinnedSites += 1 }
        }
        return pinnedSites
    }

    // MARK: - Google Tile

    private func shouldAddGoogle(availableSpaceCount: Int) -> Bool {
        googleTopSiteManager.shouldAddGoogleTopSite(hasSpace: availableSpaceCount > 0)
    }

    private func addGoogleTopSite(sites: inout [Site]) {
        googleTopSiteManager.addGoogleTopSite(sites: &sites)
    }

    // MARK: - Sponsored tiles (Contiles)

    private var shouldLoadSponsoredTiles: Bool {
        return profile.prefs.boolForKey(PrefsKeys.UserFeatureFlagPrefs.SponsoredShortcuts) ?? true
    }

    private var shouldAddSponsoredTiles: Bool {
        return !contiles.isEmpty && shouldLoadSponsoredTiles
    }

    /// Google tile has precedence over Sponsored Tiles, if Google tile is present
    private func getSponsoredNumberTiles(shouldAddGoogle: Bool, availableSpaceCount: Int) -> Int {
        let googleAdjustedSpaceCount = availableSpaceCount - GoogleTopSiteManager.Constants.reservedSpaceCount
        return shouldAddGoogle ? googleAdjustedSpaceCount : availableSpaceCount
    }
}

// MARK: Site Array extension
private extension Array where Element == Site {
    /// Add sponsored tiles to the top sites.
    /// - Parameters:
    ///   - sponsoredTileSpaces: The number of spaces available for sponsored tiles
    ///   - contiles: An array of Contiles a type of tiles belonging in the Shortcuts section on the Firefox home page.
    ///   - defaultSearchEngine: The default engine to filter sponsored tiles against
    ///   - maxNumberOfSponsoredTile: maximum number of sponsored tiles
    mutating func addSponsoredTiles(sponsoredTileSpaces: Int,
                                    contiles: [Contile],
                                    defaultSearchEngine: OpenSearchEngine?,
                                    maxNumberOfSponsoredTile: Int = 2) {
        guard maxNumberOfSponsoredTile > 0 else { return }
        var siteAddedCount = 0

        for (index, _) in contiles.enumerated() {
            guard siteAddedCount < sponsoredTileSpaces, let contile = contiles[safe: index] else { return }
            let site = SponsoredTile(contile: contile)

            // Show the next sponsored site if site is already present in the pinned sites
            // or if it's the default search engine
            guard !siteIsAlreadyPresent(site: site),
                  SponsoredTileDataUtility().shouldAdd(site: site, with: defaultSearchEngine)
            else { continue }

            insert(site, at: siteAddedCount)
            siteAddedCount += 1

            // Do not add more sponsored tile if we reach the maximum
            guard siteAddedCount < maxNumberOfSponsoredTile else { break }
        }
    }

    // Keeping the order of the sites, we remove duplicate tiles.
    // Ex: If a sponsored tile is present then it has precedence over the history sites.
    // Ex: A default site is present but user has recent history site of the same site.
    // That recent history tile won't be added.
    mutating func removeDuplicates() {
        var alreadyThere = Set<Site>()
        let uniqueSites = compactMap { (site) -> Site? in
            // Do not remove sponsored tiles or pinned tiles duplicates
            guard (site as? SponsoredTile) == nil && (site as? PinnedSite) == nil else {
                alreadyThere.insert(site)
                return site
            }

            let siteDomain = site.url.asURL?.shortDomain
            let shouldAddSite = !alreadyThere.contains(where: { $0.url.asURL?.shortDomain == siteDomain })
            // If shouldAddSite or site domain was not found, then insert the site
            guard shouldAddSite || siteDomain == nil else { return nil }
            alreadyThere.insert(site)

            return site
        }

        self = uniqueSites
    }

    // We don't add a sponsored tile if that domain site is already pinned by the user.
    private func siteIsAlreadyPresent(site: Site) -> Bool {
        let siteDomain = site.url.asURL?.shortDomain
        return !filter { ($0.url.asURL?.shortDomain == siteDomain) && (($0 as? PinnedSite) != nil) }.isEmpty
    }
}

// MARK: - DataObserverDelegate
extension TopSitesDataAdaptorImplementation: DataObserverDelegate {
    func didInvalidateDataSource(forceRefresh forced: Bool) {
        guard forced else { return }
        loadTopSitesData()
    }
}

// MARK: - Notifiable protocol
extension TopSitesDataAdaptorImplementation: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .ProfileDidFinishSyncing,
                .PrivateDataClearedHistory,
                .FirefoxAccountChanged,
                .TopSitesUpdated,
                .DefaultSearchEngineUpdated:
            self.didInvalidateDataSource(forceRefresh: true)
        default:
            break
        }
    }
}
