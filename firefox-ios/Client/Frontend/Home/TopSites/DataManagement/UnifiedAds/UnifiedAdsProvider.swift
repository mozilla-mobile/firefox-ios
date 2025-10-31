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
    func fetchTiles(
        timestamp: Shared.Timestamp = Date.now(), completion: @escaping (UnifiedTileResult) -> Void
    ) {
        fetchTiles(timestamp: timestamp, completion: completion)
    }
}

final class UnifiedAdsProvider: URLCaching, UnifiedAdsProviderInterface, FeatureFlaggable, Sendable {
    private let adsClient: MozAdsClientProtocol
    private static let prodResourceEndpoint = "https://ads.mozilla.org/v1/ads"
    static let stagingResourceEndpoint = "https://ads.allizom.org/v1/ads"
    let maxCacheAge: Shared.Timestamp = OneMinuteInMilliseconds * 30
    let urlCache: URLCache
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
        adsClient: MozAdsClientProtocol = RustAdsClient.shared,
        networking: ContileNetworking = DefaultContileNetwork(
            with: NetworkUtils.defaultURLSession()),
        urlCache: URLCache = URLCache.shared,
        logger: Logger = DefaultLogger.shared
    ) {
        self.adsClient = adsClient
        self.logger = logger
        self.networking = networking
        self.urlCache = urlCache
    }

    private struct AdPlacement: Codable {
        let placement: String
        let count: Int
    }

    private struct RequestBody: Codable {
        let context_id: String
        let placements: [AdPlacement]
    }

    func fetchTiles(
        timestamp: Shared.Timestamp = Date.now(), completion: @escaping (UnifiedTileResult) -> Void
    ) {
        if featureFlags.isFeatureEnabled(.adsClient, checking: .buildOnly) {
            fetchTilesWithAdsClient(completion: completion)
        } else {
            guard let request = buildRequest() else {
                completion(.failure(Error.noDataAvailable))
                return
            }

            // FXIOS-10798 - URLCache doesn't retrieve from cache if there's an httpBody set on the request
            var cacheRequest = request
            cacheRequest.httpBody = nil
            if let cachedData = findCachedData(
                for: cacheRequest, timestamp: timestamp, maxCacheAge: maxCacheAge) {
                decode(data: cachedData, completion: completion)
            } else {
                fetchTiles(request: request, completion: completion)
            }
        }
    }

    private func buildRequest() -> URLRequest? {
        guard let resourceEndpoint = resourceEndpoint else {
            logger.log(
                "The resource URL is invalid: \(String(describing: resourceEndpoint))",
                level: .warning,
                category: .homepage)
            return nil
        }

        guard let contextId = TelemetryContextualIdentifier.contextId else {
            logger.log(
                "No context id: \(String(describing: TelemetryContextualIdentifier.contextId))",
                level: .warning,
                category: .homepage)
            return nil
        }

        let requestBody = RequestBody(
            context_id: contextId,
            placements: [
                AdPlacement(placement: TileOrder.position1.rawValue, count: 1),
                AdPlacement(placement: TileOrder.position2.rawValue, count: 1),
            ]
        )

        var request = URLRequest(url: resourceEndpoint)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            logger.log(
                "The request body is invalid: \(String(describing: requestBody))",
                level: .warning,
                category: .homepage)
            return nil
        }
        return request
    }

    private func fetchTiles(request: URLRequest, completion: @escaping (UnifiedTileResult) -> Void) {
        networking.data(from: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let result):
                // FXIOS-10798 - URLCache doesn't retrieve from cache if there's an httpBody set on the request
                var cacheRequest = request
                cacheRequest.httpBody = nil
                self.cache(response: result.response, for: cacheRequest, with: result.data)
                self.decode(data: result.data, completion: completion)
            case .failure:
                completion(.failure(Error.noDataAvailable))
            }
        }
    }

    private func fetchTilesWithAdsClient(completion: @escaping (UnifiedTileResult) -> Void) {
        self.logger.log("Fetching tiles with ads client", level: .info, category: .homepage)
        let mozAdRequests = [
            MozAdsPlacementRequest(placementId: TileOrder.position1.rawValue, iabContent: nil),
            MozAdsPlacementRequest(placementId: TileOrder.position2.rawValue, iabContent: nil)
        ]
        do {
            let mozAdsPlacements = try self.adsClient.requestAds(mozAdRequests: mozAdRequests, options: nil)
            let unifiedTiles: [UnifiedTile] = mozAdsPlacements.map { name, mozAdsPlacement in
                UnifiedTile.from(name: name, mozAdsPlacement: mozAdsPlacement)
            }
            self.logger.log("Ads client request successful", level: .info, category: .homepage)
            // TODO(Regression): we need to implement the cache feature in the Rust component
            completion(.success(unifiedTiles))
        } catch let error {
            self.logger.log("Ads client request failed: \(error)", level: .warning, category: .homepage)
            completion(.failure(Error.noDataAvailable))
        }
    }

    private func decode(data: Data, completion: @escaping (UnifiedTileResult) -> Void) {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let tilesDictionary = try decoder.decode([String: [UnifiedTile]].self, from: data)
            let placementOrder = [TileOrder.position1.rawValue, TileOrder.position2.rawValue]
            let tiles = placementOrder.compactMap { tilesDictionary[$0] }.flatMap { $0 }

            guard !tiles.isEmpty else {
                completion(.failure(Error.noDataAvailable))
                return
            }
            completion(.success(tiles))
        } catch let error {
            self.logger.log(
                "Unable to parse with error: \(error)",
                level: .warning,
                category: .homepage)
            completion(.failure(Error.noDataAvailable))
        }
    }

    private var resourceEndpoint: URL? {
        if featureFlags.isCoreFeatureEnabled(.useStagingContileAPI) {
            return URL(string: UnifiedAdsProvider.stagingResourceEndpoint)
        }
        return URL(string: UnifiedAdsProvider.prodResourceEndpoint)
    }
}
