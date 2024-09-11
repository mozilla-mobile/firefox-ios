// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

typealias ContileResult = Swift.Result<[Contile], Error>

protocol ContileProviderInterface {
    /// Fetch contiles either from cache or backend
    /// - Parameters:
    ///   - timestamp: The timestamp to retrieve from cache, useful for tests. Default is Date.now()
    ///   - completion: Returns an array of Contile, can be empty
    func fetchContiles(timestamp: Timestamp, completion: @escaping (ContileResult) -> Void)
}

extension ContileProviderInterface {
    func fetchContiles(timestamp: Timestamp = Date.now(), completion: @escaping (ContileResult) -> Void) {
        fetchContiles(timestamp: timestamp, completion: completion)
    }
}

/// `Contile` is short for contextual tiles. This provider returns data that is used in
/// Shortcuts (Top Sites) section on the Firefox home page.
class ContileProvider: ContileProviderInterface, URLCaching, FeatureFlaggable {
    private static let contileProdResourceEndpoint = "https://ads.mozilla.org/v1/tiles"
    static let contileStagingResourceEndpoint = "https://ads.allizom.org/v1/tiles"

    var urlCache: URLCache
    private var logger: Logger
    private var networking: ContileNetworking

    init(
        networking: ContileNetworking = DefaultContileNetwork(
            with: makeURLSession(userAgent: UserAgent.mobileUserAgent(),
                                 configuration: URLSessionConfiguration.default)),
        urlCache: URLCache = URLCache.shared,
        logger: Logger = DefaultLogger.shared
    ) {
            self.logger = logger
        self.networking = networking
        self.urlCache = urlCache
    }

    enum Error: Swift.Error {
        case noDataAvailable
    }

    func fetchContiles(timestamp: Timestamp = Date.now(), completion: @escaping (ContileResult) -> Void) {
        guard let resourceEndpoint = resourceEndpoint else {
            logger.log("The Contile resource URL is invalid: \(String(describing: resourceEndpoint))",
                       level: .warning,
                       category: .homepage)
            completion(.failure(Error.noDataAvailable))
            return
        }

        let request = URLRequest(url: resourceEndpoint,
                                 cachePolicy: .reloadIgnoringCacheData,
                                 timeoutInterval: 5)

        if let cachedData = findCachedData(for: request, timestamp: timestamp) {
            decode(data: cachedData, completion: completion)
        } else {
            fetchContiles(request: request, completion: completion)
        }
    }

    private func fetchContiles(request: URLRequest, completion: @escaping (ContileResult) -> Void) {
        networking.data(from: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let result):
                self.cache(response: result.response, for: request, with: result.data)
                self.decode(data: result.data, completion: completion)
            case .failure:
                completion(.failure(Error.noDataAvailable))
            }
        }
    }

    private func decode(data: Data, completion: @escaping (ContileResult) -> Void) {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let rootNote = try decoder.decode(Contiles.self, from: data)
            var contiles = rootNote.tiles
            guard !contiles.isEmpty else {
                completion(.failure(Error.noDataAvailable))
                return
            }
            contiles.sort { $0.position ?? 0 < $1.position ?? 0 }
            completion(.success(contiles))
        } catch let error {
            self.logger.log("Unable to parse with error: \(error)",
                            level: .warning,
                            category: .homepage)
            completion(.failure(Error.noDataAvailable))
        }
    }

    private var resourceEndpoint: URL? {
        if featureFlags.isCoreFeatureEnabled(.useStagingContileAPI) {
            return URL(string: ContileProvider.contileStagingResourceEndpoint, invalidCharacters: false)
        }
        return URL(string: ContileProvider.contileProdResourceEndpoint, invalidCharacters: false)
    }
}
