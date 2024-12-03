// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

typealias UnifiedTileResult = Swift.Result<[UnifiedTile], Error>

/// Used only for sponsored tiles content and telemetry. This is aiming to be a temporary API
/// as we'll migrate to using A-S for this at some point in 2025
protocol UnifiedAdsProviderInterface {
    /// Fetch tiles either from cache or backend
    /// - Parameters:
    ///   - timestamp: The timestamp to retrieve from cache, useful for tests. Default is Date.now()
    ///   - completion: Returns an array of Tiles, can be empty
    func fetchTiles(timestamp: Timestamp, completion: @escaping (UnifiedTileResult) -> Void)
}

extension UnifiedAdsProviderInterface {
    func fetchTiles(timestamp: Timestamp = Date.now(), completion: @escaping (UnifiedTileResult) -> Void) {
        fetchTiles(timestamp: timestamp, completion: completion)
    }
}

class UnifiedAdsProvider: URLCaching, UnifiedAdsProviderInterface, FeatureFlaggable {
    private static let prodResourceEndpoint = "https://ads.mozilla.org/v1/ads"
    static let stagingResourceEndpoint = "https://ads.allizom.org/v1/ads"

    var urlCache: URLCache
    private var logger: Logger
    private var networking: ContileNetworking

    enum Error: Swift.Error {
        case noDataAvailable
    }

    init(
        networking: ContileNetworking = DefaultContileNetwork(with: NetworkUtils.defaultURLSession()),
        urlCache: URLCache = URLCache.shared,
        logger: Logger = DefaultLogger.shared
    ) {
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

    func fetchTiles(timestamp: Timestamp = Date.now(), completion: @escaping (UnifiedTileResult) -> Void) {
        guard let request = buildRequest() else {
            completion(.failure(Error.noDataAvailable))
            return
        }

        if let cachedData = findCachedData(for: request, timestamp: timestamp) {
            decode(data: cachedData, completion: completion)
        } else {
            fetchTiles(request: request, completion: completion)
        }
    }

    private func buildRequest() -> URLRequest? {
        guard let resourceEndpoint = resourceEndpoint else {
            logger.log("The resource URL is invalid: \(String(describing: resourceEndpoint))",
                       level: .warning,
                       category: .legacyHomepage)
            return nil
        }

        guard let contextId = TelemetryContextualIdentifier.contextId else {
            logger.log("No context id: \(String(describing: TelemetryContextualIdentifier.contextId))",
                       level: .warning,
                       category: .legacyHomepage)
            return nil
        }

        let requestBody = RequestBody(
            context_id: contextId,
            placements: [
                AdPlacement(placement: "newtab_mobile_tile_1", count: 1),
                AdPlacement(placement: "newtab_mobile_tile_2", count: 1)
            ]
        )

        print("Laurie - contextId \(contextId)")

        var request = URLRequest(url: resourceEndpoint)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let jsonData = try JSONEncoder().encode(requestBody)
            request.httpBody = jsonData
        } catch {
            logger.log("The request body is invalid: \(String(describing: requestBody))",
                       level: .warning,
                       category: .legacyHomepage)
            return nil
        }
        return request
    }

    private func fetchTiles(request: URLRequest, completion: @escaping (UnifiedTileResult) -> Void) {
        networking.data(from: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let result):
                self.cache(response: result.response, for: request, with: result.data)
                self.decode(data: result.data, completion: completion)
            case .failure:
                print("Laurie - no data")
                completion(.failure(Error.noDataAvailable))
            }
        }
    }

    private func decode(data: Data, completion: @escaping (UnifiedTileResult) -> Void) {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let tilesDictionary = try decoder.decode([String: [UnifiedTile]].self, from: data)
            let tiles = tilesDictionary.values.flatMap { $0 }

            guard !tiles.isEmpty else {
                completion(.failure(Error.noDataAvailable))
                return
            }
            completion(.success(tiles))
        } catch let error {
            self.logger.log("Unable to parse with error: \(error)",
                            level: .warning,
                            category: .legacyHomepage)
            completion(.failure(Error.noDataAvailable))
        }
    }

    private var resourceEndpoint: URL? {
//        if featureFlags.isCoreFeatureEnabled(.useStagingContileAPI) {
//            return URL(string: UnifiedAdsProvider.stagingResourceEndpoint, invalidCharacters: false)
//        }
        return URL(string: UnifiedAdsProvider.prodResourceEndpoint, invalidCharacters: false)
    }
}
