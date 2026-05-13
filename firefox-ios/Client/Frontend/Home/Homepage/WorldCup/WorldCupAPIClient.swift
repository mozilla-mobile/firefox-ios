// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// Thin Swift wrapper around the FFI-generated `MozillaAppServices.WorldCupClient`.
/// Exposes the merino WCS endpoints as parsed Swift values, isolating callers from
/// raw JSON strings and from the FFI surface itself (which simplifies mocking in tests).
final class WorldCupAPIClient: WorldCupAPIClientProtocol, @unchecked Sendable {
    static let emptyConfig = WorldCupConfig(baseHost: nil)

    private let client: WorldCupClient
    private let decoder: JSONDecoder
    private let matchesStrategy: WorldCupFetchStrategyProtocol
    private let liveStrategy: WorldCupFetchStrategyProtocol
    private let teamsStrategy: WorldCupFetchStrategyProtocol

    init(config: WorldCupConfig = WorldCupAPIClient.emptyConfig,
         matchesStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy(),
         liveStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy(),
         teamsStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy()) throws {
        self.client = try WorldCupClient(config: config)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
        self.matchesStrategy = matchesStrategy
        self.liveStrategy = liveStrategy
        self.teamsStrategy = teamsStrategy
    }

    /// Low-level sync matches fetch + decode. Throws on FFI error or decode failure.
    /// Pass a 3-letter FIFA team key to filter the response to one team's fixtures.
    func fetch(_ query: WorldCupQuery, team: String? = nil) throws -> WorldCupMatchesResponse? {
        let options = Self.options(forTeam: team)
        let json = switch query {
        case .matches: try client.getMatches(options: options)
        case .live:    try client.getLive(options: options)
        }
        return try decode(json)
    }

    /// Low-level sync teams fetch + decode. Throws on FFI error or decode failure.
    /// Pass a 3-letter FIFA team key to scope the roster response.
    func fetchTeams(team: String? = nil) throws -> WorldCupTeamsResponse? {
        let json = try client.getTeams(options: Self.options(forTeam: team))
        return try decodeTeams(json)
    }

    /// High-level async loader: delegates to the strategy configured for the
    /// given query (live vs non-live). The strategy decides how to call `fetch`
    /// (single attempt, retry, etc.) and returns the decoded merino response
    /// or a `WorldCupLoadError` the UI can pattern-match on.
    /// Callers transform the success response into a view-model.
    func loadMatches(query: WorldCupQuery,
                     team: String? = nil) async -> Result<WorldCupMatchesResponse?, WorldCupLoadError> {
        let strategy: WorldCupFetchStrategyProtocol = switch query {
        case .matches: matchesStrategy
        case .live:    liveStrategy
        }
        return await strategy.loadMatches(using: self, query: query, team: team)
    }

    /// High-level async teams loader. Delegates to the configured teams
    /// strategy and returns either the decoded response or a
    /// `WorldCupLoadError` the UI can pattern-match on.
    func loadTeams(team: String? = nil) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        await teamsStrategy.loadTeams(using: self, team: team)
    }

    private static func options(forTeam team: String?) -> WorldCupOptions {
        WorldCupOptions(
            limit: nil,
            teams: team.map { [$0] },
            acceptLanguage: nil,
            date: nil
        )
    }

    private func decode(_ json: String?) throws -> WorldCupMatchesResponse? {
        guard let data = json?.data(using: .utf8) else { return nil }
        return try decoder.decode(WorldCupMatchesResponse.self, from: data)
    }

    private func decodeTeams(_ json: String?) throws -> WorldCupTeamsResponse? {
        guard let data = json?.data(using: .utf8) else { return nil }
        return try decoder.decode(WorldCupTeamsResponse.self, from: data)
    }
}
