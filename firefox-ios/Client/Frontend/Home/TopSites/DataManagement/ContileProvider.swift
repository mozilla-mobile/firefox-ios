// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared
import Storage

typealias ContileResult = Swift.Result<[Contile], Error>

protocol ContileProviderInterface: Sendable {
    /// Fetch contiles either from cache or backend
    /// - Parameters:
    ///   - timestamp: The timestamp to retrieve from cache, useful for tests. Default is Date.now()
    ///   - completion: Returns an array of Contile, can be empty
    func fetchContiles(timestamp: Shared.Timestamp, completion: @escaping (ContileResult) -> Void)
}

extension ContileProviderInterface {
    func fetchContiles(timestamp: Shared.Timestamp = Date.now(), completion: @escaping (ContileResult) -> Void) {
        fetchContiles(timestamp: timestamp, completion: completion)
    }
}

/// `Contile` is short for contextual tiles. This provider returns data that is used in
/// Shortcuts (Top Sites) section on the Firefox home page.
final class ContileProvider: ContileProviderInterface, URLCaching, FeatureFlaggable {
    let urlCache: URLCache
    private let logger: Logger
    private let networking: ContileNetworking
    private let adsClient: MozAdsClient = RustAdsClient.shared

    init(
        networking: ContileNetworking = DefaultContileNetwork(
            with: makeURLSession(userAgent: UserAgent.mobileUserAgent(),
                                 configuration: URLSessionConfiguration.defaultMPTCP)),
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

    func fetchContiles(timestamp: Shared.Timestamp = Date.now(), completion: @escaping (ContileResult) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performContileFetch(completion: completion)
        }
    }

    private func performContileFetch(completion: @escaping (ContileResult) -> Void) {
        let placementIds = [
            "newtab_mobile_tile_1",
            "newtab_mobile_tile_2"
        ]
        let configs = placementIds.map { MozAdsPlacementConfig(placementId: $0, fixedSize: nil, iabContent: nil) }

        do {
            let response = try adsClient.requestAds(mozAdConfigs: configs)
            let items: [Contile] = placementIds.enumerated().compactMap { index, key in
                guard let placement = response[key] else { return nil }
                let content = placement.content
                guard
                    let url = content.url,
                    let imageUrl = content.imageUrl,
                    let callbacks = content.callbacks,
                    let click = callbacks.click,
                    let impression = callbacks.impression
                else { return nil }

                let name = content.altText ?? ""
                return Contile(
                    id: 0,
                    name: name,
                    url: url,
                    clickUrl: click,
                    imageUrl: imageUrl,
                    imageSize: 0,
                    impressionUrl: impression,
                    position: index + 1
                )
            }

            guard !items.isEmpty else {
                completion(.failure(Error.noDataAvailable))
                return
            }
            completion(.success(items))
        } catch {
            logger.log("Contile ads client request failed", level: .warning, category: .legacyHomepage)
            completion(.failure(Error.noDataAvailable))
        }
    }
}
