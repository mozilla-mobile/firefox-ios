// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Storage

/// To be cleaned up once https://github.com/mozilla-mobile/firefox-ios/pull/10182/files is merged
protocol ContileProvider {
    typealias Result = Swift.Result<[Contile], Error>

    func fetchContiles(completion: @escaping (Result) -> Void)
}

struct Contile: Codable {
    let id: Int
    let name: String
    let url: String
    let clickUrl: String
    let imageURL: String
    let imageSize: Int
    let impressionUrl: String
    let position: Int?
}

// TODO: Use in tests only when provider exists
class ContileProviderMock: ContileProvider {

    var shouldSucceed: Bool = true
    private var successData: [Contile]
    private var failureResult = Result.failure(Error.invalidData)
    private var successResult: ContileProvider.Result

    static var mockSuccessData: [Contile] {
        return [Contile(id: 1,
                        name: "Firefox",
                        url: "https://firefox.com",
                        clickUrl: "https://firefox.com/click",
                        imageURL: "https://test.com/image1.jpg",
                        imageSize: 200,
                        impressionUrl: "https://test.com",
                        position: 1),
                Contile(id: 2,
                        name: "Mozilla",
                        url: "https://mozilla.com",
                        clickUrl: "https://mozilla.com/click",
                        imageURL: "https://test.com/image2.jpg",
                        imageSize: 200,
                        impressionUrl: "https://example.com",
                        position: 2)]
    }

    init(successData: [Contile] = []) {
        self.successData = successData
        self.successResult = Result.success(successData)
    }

    func fetchContiles(completion: @escaping (ContileProvider.Result) -> Void) {
        completion(shouldSucceed ? successResult : failureResult)
    }

    enum Error: Swift.Error {
        case invalidData
    }
}
/// End of code to clean up

protocol FxHomeTopSitesManagerDelegate: AnyObject {
    func reloadTopSites()
}

class FxHomeTopSitesManager {

    private let contileProvider: ContileProvider
    private let googleTopSiteManager: GoogleTopSiteManager
    private let profile: Profile

    private var topSites: [HomeTopSite] = []
    private var historySites: [Site] = []
    private var contiles: [Contile] = []

    private let dataQueue = DispatchQueue(label: "com.moz.topSitesManager.queue")
    weak var delegate: FxHomeTopSitesManagerDelegate?
    lazy var topSiteHistoryManager = TopSiteHistoryManager(profile: profile)
    
    init(profile: Profile) {
        self.profile = profile
        self.googleTopSiteManager = GoogleTopSiteManager(prefs: profile.prefs)
        self.contileProvider = ContileProviderMock(successData: ContileProviderMock.mockSuccessData)
        topSiteHistoryManager.delegate = self
    }

    func getSite(index: Int) -> HomeTopSite? {
        guard !topSites.isEmpty, index < topSites.count, index >= 0 else { return nil }
        return topSites[index]
    }

    func getSiteDetail(index: Int) -> Site? {
        guard !topSites.isEmpty, index < topSites.count, index >= 0 else { return nil }
        return topSites[index].site
    }

    var hasData: Bool {
        return !historySites.isEmpty
    }

    var siteCount: Int {
        return historySites.count
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
            dataLoadingCompletion?()
        }
    }

    private func loadContiles(group: DispatchGroup) {
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

        if shouldAddSponsoredTiles(pinnedSiteCount: pinnedSiteCount,
                             totalNumberOfShownTiles: totalNumberOfShownTiles) {
            addSponsoredTiles(sites: &sites)
        }

        if googleTopSiteManager.shouldAddGoogleTopSite(pinnedSiteCount: pinnedSiteCount,
                                                       totalNumberOfShownTiles: totalNumberOfShownTiles) {
            googleTopSiteManager.addGoogleTopSite(maxItems: totalNumberOfShownTiles, sites: &sites)
        }

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

    private func countPinnedSites(sites: [Site]) -> Int {
        var pinnedSites = 0
        sites.forEach {
            if let _ = $0 as? PinnedSite { pinnedSites += 1 }
        }
        return pinnedSites
    }

    // MARK: - Sponsored tiles (Contiles)

    static let maximumNumberOfSponsoredTile = 1

    /// Check if Sponsored Tiles can be added to the top sites.
    /// We don't add contiles if number of pins exeeds the available top sites spaces available and
    /// ensure that Google tile has precedence over Sponsored Tiles
    /// - Parameters:
    ///   - pinnedSiteCount: The number of sites that are pinned
    ///   - totalNumberOfShownTiles: The total number of tiles shown to the user
    /// - Returns: True when contiles can be added
    func shouldAddSponsoredTiles(pinnedSiteCount: Int, totalNumberOfShownTiles: Int) -> Bool {
        // TODO: Will check for user preference here with https://mozilla-hub.atlassian.net/browse/FXIOS-3469
        // TODO: Feature flag check
        return !contiles.isEmpty && (pinnedSiteCount < totalNumberOfShownTiles - GoogleTopSiteManager.Constants.reservedSpaceCount)
    }

    /// Add a sponsored tiles to the top sites.
    /// - Parameters:
    ///   - sites: The top sites to add the sponsored tile to
    func addSponsoredTiles(sites: inout [Site]) {
        // TODO: Add check to ensure tile doesn't exists (don't duplicate). Check with URL
        // TODO: Logic to support only one contile (the first one)
        // TODO: Should I order depending on the position of the Contile? Asked Loren.
        let site = SponsoredTile(contile: contiles[0])
        sites.insert(site, at: 0)
    }
}

extension FxHomeTopSitesManager: DataObserverDelegate {

    func didInvalidateDataSources(refresh forced: Bool, topSitesRefreshed: Bool) {
        guard forced else { return }
        delegate?.reloadTopSites()
    }
}
