// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

typealias UnifiedTileResult = Swift.Result<[UnifiedTile], Error>

protocol UnifiedAdsProviderInterface: Sendable {
    /// Fetch unified ads tiles.
    ///
    /// When tiles were fetched recently (see `UnifiedAdsProvider.maxTileStaleness`), the
    /// completion is called synchronously with the last known tiles and a refresh runs in
    /// the background for the next caller. Otherwise the blocking ads client request runs
    /// on a dedicated queue and the completion is called from that queue.
    /// - Parameters:
    ///   - timestamp: The timestamp to validate the cache against, useful for tests. Default is Date.now()
    ///   - completion: Returns an array of Tiles, can be empty
    func fetchTiles(timestamp: Shared.Timestamp, completion: @escaping @Sendable (UnifiedTileResult) -> Void)
}

extension UnifiedAdsProviderInterface {
    func fetchTiles(timestamp: Shared.Timestamp = Date.now(), completion: @escaping @Sendable (UnifiedTileResult) -> Void) {
        fetchTiles(timestamp: timestamp, completion: completion)
    }
}

final class UnifiedAdsProvider: UnifiedAdsProviderInterface, @unchecked Sendable {
    private let adsClient: MozAdsClient
    private let logger: Logger
    private let fetchQueue: DispatchQueueInterface

    /// How long the last successfully fetched tiles may keep being served while they get
    /// refreshed in the background. The ads client refreshes its own cache every 30 minutes
    /// with a network request that can block the homepage's top sites section on slow
    /// networks (see FXIOS-15847), so serving the last known tiles for up to an hour keeps
    /// that section instant without letting stale ads live for longer than one extra cycle.
    static let maxTileStaleness: Timestamp = OneHourInMilliseconds

    private let cacheLock = NSLock()
    private var lastKnownTiles: [UnifiedTile]?
    private var lastFetchTimestamp: Timestamp = 0
    private var isRevalidating = false

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
        logger: Logger = DefaultLogger.shared,
        fetchQueue: DispatchQueueInterface = DispatchQueue(
            label: "org.mozilla.ios.unified-ads-fetch",
            qos: .userInitiated
        )
    ) {
        self.adsClient = adsClientFactory.createClient()
        self.logger = logger
        self.fetchQueue = fetchQueue
    }

    private struct AdPlacement: Codable {
        let placement: String
        let count: Int
    }

    private struct RequestBody: Codable {
        let context_id: String
        let placements: [AdPlacement]
    }

    func fetchTiles(timestamp: Shared.Timestamp = Date.now(),
                    completion: @escaping @Sendable (UnifiedTileResult) -> Void) {
        if let lastKnownTiles = lastKnownTiles(at: timestamp) {
            logger.log("Serving last known tiles while revalidating in the background",
                       level: .debug,
                       category: .homepage)
            completion(.success(lastKnownTiles))
            revalidateLastKnownTiles(timestamp: timestamp)
            return
        }

        fetchQueue.async { [self] in
            completion(requestTiles(timestamp: timestamp))
        }
    }

    /// Runs the blocking ads client request and caches the tiles on success. The dedicated
    /// `fetchQueue` keeps a slow request from tying up a Swift Concurrency cooperative
    /// thread, and caching here means results that arrive after the top sites section
    /// stopped waiting for them still get served on the next homepage build.
    private func requestTiles(timestamp: Shared.Timestamp) -> UnifiedTileResult {
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
                return UnifiedTile.from(name: placement, mozAdsTile: mozAdsTile)
            }

            logger.log("Ads client request successful", level: .info, category: .homepage)
            storeLastKnownTiles(unifiedTiles, fetchedAt: timestamp)
            return .success(unifiedTiles)
        } catch let error {
            logger.log("Ads client request failed: \(error)", level: .warning, category: .homepage)
            return .failure(Error.noDataAvailable)
        }
    }

    private func lastKnownTiles(at timestamp: Shared.Timestamp) -> [UnifiedTile]? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        guard let lastKnownTiles,
              timestamp >= lastFetchTimestamp,
              timestamp - lastFetchTimestamp <= Self.maxTileStaleness
        else { return nil }
        return lastKnownTiles
    }

    private func storeLastKnownTiles(_ tiles: [UnifiedTile], fetchedAt timestamp: Shared.Timestamp) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        lastKnownTiles = tiles
        lastFetchTimestamp = timestamp
    }

    /// Refreshes the last known tiles off the calling thread. A failed refresh keeps the
    /// previous tiles so they can be served until `maxTileStaleness` runs out.
    private func revalidateLastKnownTiles(timestamp: Shared.Timestamp) {
        cacheLock.lock()
        guard !isRevalidating else {
            cacheLock.unlock()
            return
        }
        isRevalidating = true
        cacheLock.unlock()

        fetchQueue.async { [self] in
            _ = requestTiles(timestamp: timestamp)
            cacheLock.lock()
            isRevalidating = false
            cacheLock.unlock()
        }
    }
}
