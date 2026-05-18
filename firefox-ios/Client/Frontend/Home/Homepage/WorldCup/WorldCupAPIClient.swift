// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// Thin Swift wrapper around the FFI-generated `MozillaAppServices.WorldCupClient`.
/// Exposes the merino WCS endpoints as parsed Swift values, isolating callers from
/// raw JSON strings and from the FFI surface itself (which simplifies mocking in tests).
///
/// Matches and live default to `WorldCupPollingFetchStrategy` (5- / 3-min
/// polling with 204 + error backoff, capped at 20 min). Teams stays one-shot
/// via `WorldCupNormalFetchStrategy`. Pass overrides for tests or to disable
/// polling.
final class WorldCupAPIClient: WorldCupAPIClientProtocol, @unchecked Sendable {
    static let emptyConfig = WorldCupConfig(baseHost: nil)

    private let client: WorldCupClient
    private let decoder: JSONDecoder
    private let matchesStrategy: WorldCupFetchStrategyProtocol
    private let liveStrategy: WorldCupFetchStrategyProtocol
    private let teamsStrategy: WorldCupFetchStrategyProtocol

    init(config: WorldCupConfig = WorldCupAPIClient.emptyConfig,
         matchesStrategy: WorldCupFetchStrategyProtocol = WorldCupPollingFetchStrategy(),
         liveStrategy: WorldCupFetchStrategyProtocol = WorldCupPollingFetchStrategy(),
         teamsStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy()) throws {
        self.client = try WorldCupClient(config: config)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
        self.matchesStrategy = matchesStrategy
        self.liveStrategy = liveStrategy
        self.teamsStrategy = teamsStrategy
    }

    /// Convenience init that points the FFI at a custom host. Pass `nil` or
    /// an empty string to use the default merino host. Intended for local
    /// dev/beta testing against a non-production merino instance.
    convenience init(baseHost: String?,
                     matchesStrategy: WorldCupFetchStrategyProtocol = WorldCupPollingFetchStrategy(),
                     liveStrategy: WorldCupFetchStrategyProtocol = WorldCupPollingFetchStrategy(),
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
    func fetchMatches(team: String? = nil) throws -> WorldCupMatchesResponse? {
        let json = try client.getMatches(options: Self.options(forTeam: team))
        return try decode(json, as: WorldCupMatchesResponse.self)
    }

    /// Low-level sync live fetch + decode. Throws on FFI error or decode failure.
    /// Pass a 3-letter FIFA team key to filter the response to one team's fixtures.
    func fetchLive(team: String? = nil) throws -> WorldCupLiveResponse? {
        let json = try client.getLive(options: Self.options(forTeam: team))
        return try decode(json, as: WorldCupLiveResponse.self)
    }

    /// Low-level sync teams fetch + decode. Throws on FFI error or decode failure.
    /// Pass a 3-letter FIFA team key to scope the roster response.
    func fetchTeams(team: String? = nil) throws -> WorldCupTeamsResponse? {
        let json = try client.getTeams(options: Self.options(forTeam: team))
        return try decode(json, as: WorldCupTeamsResponse.self)
    }

    func matchesStream(team: String? = nil) -> WorldCupMatchesStream {
        matchesStrategy.matchesStream(using: self, team: team)
    }

    func liveStream(team: String? = nil) -> WorldCupLiveStream {
        liveStrategy.liveStream(using: self, team: team)
    }

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

    private func decode<T: Decodable>(_ json: String?, as type: T.Type) throws -> T? {
        guard let data = json?.data(using: .utf8) else { return nil }
        return try decoder.decode(type, from: data)
    }
}
