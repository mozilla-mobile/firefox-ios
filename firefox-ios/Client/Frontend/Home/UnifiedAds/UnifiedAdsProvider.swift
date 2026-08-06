// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices

typealias UnifiedTileResult = Swift.Result<[UnifiedTile], Error>

protocol UnifiedAdsProviderInterface: Sendable {
    /// Fetch unified ads tiles
    /// - Parameter completion: Returns an array of Tiles, can be empty
    func fetchTiles(completion: @escaping @Sendable (UnifiedTileResult) -> Void)
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

    func fetchTiles(completion: @escaping @Sendable (UnifiedTileResult) -> Void) {
        logger.log("Fetching tiles with ads client", level: .debug, category: .homepage)
        let mozAdRequests = TileOrder.placementOrder.map {
            MozAdsPlacementRequest(iabContent: nil, placementId: $0)
        }
        do {
            let mozAdsTiles = try adsClient.requestTileAds(
                mozAdRequests: mozAdRequests,
                options: nil
            )
            let unifiedTiles: [UnifiedTile] = TileOrder.placementOrder.compactMap { placement in
                guard let mozAdsTile = mozAdsTiles[placement] else { return nil }
                return UnifiedTile.from(mozAdsTile: mozAdsTile)
            }

            logger.log("Ads client request successful", level: .info, category: .homepage)
            completion(.success(unifiedTiles))
        } catch let error {
            logger.log("Ads client request failed: \(error)", level: .warning, category: .homepage)
            completion(.failure(Error.noDataAvailable))
        }
    }
}
