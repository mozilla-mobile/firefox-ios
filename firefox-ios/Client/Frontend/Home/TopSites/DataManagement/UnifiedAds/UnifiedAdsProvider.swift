// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared
import Storage

typealias UnifiedTileResult = Swift.Result<[UnifiedTile], Error>

/// Used only for sponsored tiles content and telemetry. This is aiming to be a temporary API
/// as we'll migrate to using A-S for this at some point in 2025
protocol UnifiedAdsProviderInterface: Sendable {
    /// Fetch tiles either from cache or backend
    /// - Parameters:
    ///   - timestamp: The timestamp to retrieve from cache, useful for tests. Default is Date.now()
    ///   - completion: Returns an array of Tiles, can be empty
    func fetchTiles(timestamp: Shared.Timestamp, completion: @escaping (UnifiedTileResult) -> Void)
}

extension UnifiedAdsProviderInterface {
    func fetchTiles(timestamp: Shared.Timestamp = Date.now(), completion: @escaping (UnifiedTileResult) -> Void) {
        fetchTiles(timestamp: timestamp, completion: completion)
    }
}

final class UnifiedAdsProvider: URLCaching, UnifiedAdsProviderInterface, FeatureFlaggable, Sendable {
    let maxCacheAge: Shared.Timestamp = OneMinuteInMilliseconds * 30
    let urlCache: URLCache
    private let adsClient: MozAdsClient
    private let logger: Logger
    private let networking: ContileNetworking

    enum Error: Swift.Error {
        case noDataAvailable
    }

    enum TileOrder: String {
        case position1 = "newtab_mobile_tile_1"
        case position2 = "newtab_mobile_tile_2"
    }

    init(
        adsClient: MozAdsClient = Storage.RustAdsClient.shared,
        networking: ContileNetworking = DefaultContileNetwork(with: NetworkUtils.defaultURLSession()),
        urlCache: URLCache = URLCache.shared,
        logger: Logger = DefaultLogger.shared
    ) {
        self.adsClient = adsClient
        self.logger = logger
        self.networking = networking
        self.urlCache = urlCache
    }

    func fetchTiles(timestamp: Shared.Timestamp = Date.now(), completion: @escaping (UnifiedTileResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let placements = [
                MozAdsPlacementConfig(placementId: TileOrder.position1.rawValue, fixedSize: nil, iabContent: nil),
                MozAdsPlacementConfig(placementId: TileOrder.position2.rawValue, fixedSize: nil, iabContent: nil)
            ]

            do {
                let result = try self.adsClient.requestAds(mozAdConfigs: placements)
                let tiles = self.processAdsResult(result)

                if tiles.isEmpty {
                    completion(.failure(Error.noDataAvailable))
                } else {
                    completion(.success(tiles))
                }
            } catch {
                self.logger.log("Ads client request failed", level: .warning, category: .legacyHomepage)
                completion(.failure(Error.noDataAvailable))
            }
        }
    }

    private func processAdsResult(_ result: [String: MozAdsPlacement]) -> [UnifiedTile] {
        let orderedIds = [TileOrder.position1.rawValue, TileOrder.position2.rawValue]
        return orderedIds.compactMap { key in
            guard let placement = result[key] else { return nil }
            let content = placement.content

            guard
                let url = content.url,
                let imageUrl = content.imageUrl,
                let callbacks = content.callbacks,
                let click = callbacks.click,
                let impression = callbacks.impression
            else { return nil }

            let format = content.format ?? ""
            let name = content.altText ?? ""
            let blockKey = content.blockKey ?? ""

            return UnifiedTile(
                format: format,
                url: url,
                callbacks: UnifiedTileCallback(click: click, impression: impression),
                imageUrl: imageUrl,
                name: name,
                blockKey: blockKey
            )
        }
    }
}
