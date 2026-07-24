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
    /// When tiles were fetched recently (see `UnifiedAdsProvider.maxTileStaleness`), the last
    /// known tiles are returned immediately and a refresh runs in the background for the next
    /// caller. Otherwise the blocking ads client request runs on a dedicated queue, off the
    /// Swift Concurrency cooperative pool, and its result is returned once it completes.
    /// - Parameter timestamp: The timestamp to validate the cache against, useful for tests.
    ///   Defaults to `Date.now()`.
    /// - Returns: An array of tiles, which can be empty, or an error when no tiles are available.
    func fetchTiles(timestamp: Shared.Timestamp) async -> UnifiedTileResult
}

extension UnifiedAdsProviderInterface {
    func fetchTiles(timestamp: Shared.Timestamp = Date.now()) async -> UnifiedTileResult {
        await fetchTiles(timestamp: timestamp)
    }
}

/// Serves sponsored tiles for the homepage, keeping the last known tiles in memory so the top
/// sites section stays instant while the ads client's cache is revalidated in the background.
///
/// The cache is protected by actor isolation rather than a lock, and the blocking ads client
/// request is bridged onto a dedicated queue so it never ties up a Swift Concurrency
/// cooperative thread (see FXIOS-16156 / FXIOS-16307).
actor UnifiedAdsProvider: UnifiedAdsProviderInterface {
    private let adsClient: MozAdsClient
    private let logger: Logger
    private let fetchQueue: DispatchQueueInterface

    /// How long the last successfully fetched tiles may keep being served while they get
    /// refreshed in the background. The ads client refreshes its own cache every 30 minutes
    /// with a network request that can block the homepage's top sites section on slow
    /// networks (see FXIOS-15847), so serving the last known tiles for up to an hour keeps
    /// that section instant without letting stale ads live for longer than one extra cycle.
    static let maxTileStaleness: Timestamp = OneHourInMilliseconds

    private var lastKnownTiles: [UnifiedTile]?
    private var lastFetchTimestamp: Timestamp = 0
    private var revalidationTask: Task<Void, Never>?

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

    func fetchTiles(timestamp: Shared.Timestamp = Date.now()) async -> UnifiedTileResult {
        if let lastKnownTiles = validLastKnownTiles(at: timestamp) {
            logger.log("Serving last known tiles while revalidating in the background",
                       level: .debug,
                       category: .homepage)
            revalidateLastKnownTiles(timestamp: timestamp)
            return .success(lastKnownTiles)
        }

        return await requestTiles(timestamp: timestamp)
    }

    /// Runs the blocking ads client request off the actor and caches the tiles on success.
    /// Caching here means results that arrive after the top sites section stopped waiting for
    /// them still get served on the next homepage build.
    private func requestTiles(timestamp: Shared.Timestamp) async -> UnifiedTileResult {
        let result = await performRequest()
        if case .success(let tiles) = result {
            lastKnownTiles = tiles
            lastFetchTimestamp = timestamp
        }
        return result
    }

    /// Bridges the blocking `requestTileAds` FFI call onto the dedicated `fetchQueue` so it
    /// never occupies the actor's executor or a Swift Concurrency cooperative thread.
    private func performRequest() async -> UnifiedTileResult {
        let request = BlockingTileRequest(adsClient: adsClient, logger: logger)
        return await withCheckedContinuation { continuation in
            fetchQueue.async {
                continuation.resume(returning: request.run())
            }
        }
    }

    private func validLastKnownTiles(at timestamp: Shared.Timestamp) -> [UnifiedTile]? {
        guard let lastKnownTiles,
              timestamp >= lastFetchTimestamp,
              timestamp - lastFetchTimestamp <= Self.maxTileStaleness
        else { return nil }
        return lastKnownTiles
    }

    /// Refreshes the last known tiles in the background. A failed refresh keeps the previous
    /// tiles so they can be served until `maxTileStaleness` runs out. Concurrent revalidations
    /// coalesce into the one already in flight.
    private func revalidateLastKnownTiles(timestamp: Shared.Timestamp) {
        guard revalidationTask == nil else { return }
        revalidationTask = Task { [weak self] in
            _ = await self?.requestTiles(timestamp: timestamp)
            await self?.finishRevalidation()
        }
    }

    private func finishRevalidation() {
        revalidationTask = nil
    }

    /// Awaits the in-flight background revalidation, if any. Intended for tests that need to
    /// observe the refreshed cache deterministically.
    func awaitPendingRevalidation() async {
        await revalidationTask?.value
    }
}

/// Wraps the Rust-backed ads client so its blocking request can run off the actor. The client
/// is thread-safe, which this box asserts, keeping `@unchecked Sendable` narrowly scoped here
/// instead of applied to the whole provider.
private struct BlockingTileRequest: @unchecked Sendable {
    let adsClient: MozAdsClient
    let logger: Logger

    func run() -> UnifiedTileResult {
        logger.log("Fetching tiles with ads client", level: .debug, category: .homepage)
        let mozAdRequests = UnifiedAdsProvider.TileOrder.placementOrder.map {
            MozAdsPlacementRequest(iabContent: nil, placementId: $0)
        }
        do {
            let mozAdsTiles = try adsClient.requestTileAds(
                mozAdRequests: mozAdRequests,
                options: nil
            )
            let unifiedTiles: [UnifiedTile] = UnifiedAdsProvider.TileOrder.placementOrder.compactMap { placement in
                guard let mozAdsTile = mozAdsTiles[placement] else { return nil }
                return UnifiedTile.from(name: placement, mozAdsTile: mozAdsTile)
            }

            logger.log("Ads client request successful", level: .info, category: .homepage)
            return .success(unifiedTiles)
        } catch let error {
            logger.log("Ads client request failed: \(error)", level: .warning, category: .homepage)
            return .failure(UnifiedAdsProvider.Error.noDataAvailable)
        }
    }
}
