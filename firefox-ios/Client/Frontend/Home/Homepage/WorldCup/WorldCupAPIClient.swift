// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// Thin Swift wrapper around the FFI-generated `MozillaAppServices.WorldCupClient`.
/// Exposes the merino WCS endpoints as parsed Swift values, isolating callers from
/// raw JSON strings and from the FFI surface itself (which simplifies mocking in tests).
final class WorldCupAPIClient: WorldCupAPIClientProtocol, @unchecked Sendable {
    static let emptyOptions = WorldCupOptions(limit: nil, teams: nil, acceptLanguage: nil, date: nil)
    static let emptyConfig = WorldCupConfig(baseHost: nil)

    private let client: WorldCupClient
    private let decoder: JSONDecoder
    private let matchesStrategy: WorldCupFetchStrategyProtocol
    private let liveStrategy: WorldCupFetchStrategyProtocol

    init(config: WorldCupConfig = WorldCupAPIClient.emptyConfig,
         matchesStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy(),
         liveStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy()) throws {
        self.client = try WorldCupClient(config: config)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
        self.matchesStrategy = matchesStrategy
        self.liveStrategy = liveStrategy
    }

    /// Low-level sync fetch + decode. Throws on FFI error or decode failure.
    func fetch(_ query: WorldCupQuery,
               options: WorldCupOptions = WorldCupAPIClient.emptyOptions) throws -> WorldCupMatchesResponse? {
        let json = switch query {
        case .matches: try client.getMatches(options: options)
        case .live:    try client.getLive(options: options)
        }
        return try decode(json)
    }

    /// High-level async loader: delegates to the strategy configured for the
    /// given query (live vs non-live). The strategy decides how to call `fetch`
    /// (single attempt, retry, etc.) and returns the decoded merino response.
    /// Callers transform the response into a view-model.
    func loadMatches(query: WorldCupQuery) async -> WorldCupMatchesResponse? {
        let strategy: WorldCupFetchStrategyProtocol = switch query {
        case .matches: matchesStrategy
        case .live:    liveStrategy
        }
        return await strategy.loadMatches(using: self, query: query)
    }

    private func decode(_ json: String?) throws -> WorldCupMatchesResponse? {
        guard let data = json?.data(using: .utf8) else { return nil }
        return try decoder.decode(WorldCupMatchesResponse.self, from: data)
    }
}
