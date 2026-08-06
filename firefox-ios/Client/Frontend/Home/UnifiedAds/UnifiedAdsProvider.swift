// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Storage

typealias SponsoredTileResult = Swift.Result<[Site], Error>

protocol UnifiedAdsProviderInterface: Sendable {
    /// Fetch the sponsored sites shown in the Top sites section
    /// - Parameter completion: Returns an array of sponsored `Site`s, can be empty
    func fetchTiles(completion: @escaping @Sendable (SponsoredTileResult) -> Void)
}

final class UnifiedAdsProvider: UnifiedAdsProviderInterface, Sendable {
    private let adsClient: MozAdsClient
    private let logger: Logger

    enum Error: Swift.Error {
        case noDataAvailable
    }

    enum TileOrder: String, CaseIterable {
        case position1 = "newtab_mobile_tile_1"
        case position2 = "newtab_mobile_tile_2"

        /// Placement identifiers in the order tiles should be displayed.
        static var placementOrder: [String] {
            return allCases.map { $0.rawValue }
        }
    }

    init(
        adsClientFactory: MozAdsClientFactory = DefaultMozAdsClientFactory(),
        logger: Logger = DefaultLogger.shared
    ) {
        self.adsClient = adsClientFactory.createClient()
        self.logger = logger
    }

    func fetchTiles(completion: @escaping @Sendable (SponsoredTileResult) -> Void) {
        logger.log("Fetching tiles with ads client", level: .debug, category: .homepage)
        let mozAdRequests = TileOrder.placementOrder.map {
            MozAdsPlacementRequest(iabContent: nil, placementId: $0)
        }
        do {
            let mozAdsTiles = try adsClient.requestTileAds(
                mozAdRequests: mozAdRequests,
                options: nil
            )
            let sponsoredSites: [Site] = TileOrder.placementOrder.compactMap { placement in
                guard let mozAdsTile = mozAdsTiles[placement] else { return nil }
                return Self.makeSponsoredSite(from: mozAdsTile)
            }

            logger.log("Ads client request successful", level: .info, category: .homepage)
            completion(.success(sponsoredSites))
        } catch let error {
            logger.log("Ads client request failed: \(error)", level: .warning, category: .homepage)
            completion(.failure(Error.noDataAvailable))
        }
    }

    private static func makeSponsoredSite(from mozAdsTile: MozAdsTile) -> Site {
        let siteInfo = SponsoredSiteInfo(
            impressionURL: mozAdsTile.callbacks.impression,
            clickURL: mozAdsTile.callbacks.click,
            imageURL: mozAdsTile.imageUrl
        )
        return Site.createSponsoredSite(url: mozAdsTile.url, title: mozAdsTile.name, siteInfo: siteInfo)
    }
}
