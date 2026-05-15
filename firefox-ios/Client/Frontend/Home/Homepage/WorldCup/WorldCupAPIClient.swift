// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared

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

    init(config: WorldCupConfig,
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

    /// Default init that resolves the merino base host from the
    /// `WorldCupBaseHost` pref (set via the debug-menu override). A missing
    /// or empty value falls back to the FFI default merino host.
    convenience init(prefs: Prefs = (AppContainer.shared.resolve() as Profile).prefs,
                     matchesStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy(),
                     liveStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy(),
                     teamsStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy()) throws {
        try self.init(baseHost: "https://localhost:3002/", //prefs.stringForKey(PrefsKeys.HomepageSettings.WorldCupBaseHost),
                      matchesStrategy: matchesStrategy,
                      liveStrategy: liveStrategy,
                      teamsStrategy: teamsStrategy)
    }

    /// Convenience init that points the FFI at a custom host. Pass `nil` or
    /// an empty string to use the default merino host. Intended for local
    /// dev/beta testing against a non-production merino instance.
    convenience init(baseHost: String?,
                     matchesStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy(),
                     liveStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy(),
                     teamsStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy()) throws {
        let trimmed = baseHost?.trimmingCharacters(in: .whitespacesAndNewlines)
        let host = (trimmed?.isEmpty == false) ? trimmed : nil
        try self.init(config: WorldCupConfig(baseHost: host),
                      matchesStrategy: matchesStrategy,
                      liveStrategy: liveStrategy,
                      teamsStrategy: teamsStrategy)
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

    /// Anchored at June 18, 2026 so that the merino ±10-day response window
    /// [Jun 8–Jun 28] fully covers the group stage (Jun 11–27)ner
    /// in a single fetch, with one day of slack on each side.
    private static let queryDateFloor: Date = {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(identifier: "UTC")
        components.year = 2026
        components.month = 6
        components.day = 18
        return components.date!
    }()

    private static var queryDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }

    private static func options(forTeam team: String?) -> WorldCupOptions {
        WorldCupOptions(
            limit: nil,
            teams: team.map { [$0] },
            acceptLanguage: nil,
            date: queryDateFormatter.string(from: max(Date(), queryDateFloor))
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
