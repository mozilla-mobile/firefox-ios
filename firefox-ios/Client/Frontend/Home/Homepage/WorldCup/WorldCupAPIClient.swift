// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import MozillaAppServices
import Shared

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
    /// When true, the API client omits the `date` query parameter so the
    /// mock server picks its own "today".
    private let usesDevServerTimeline: Bool
    private let logger: Logger

    init(config: WorldCupConfig = WorldCupAPIClient.emptyConfig,
         usesDevServerTimeline: Bool = false,
         matchesStrategy: WorldCupFetchStrategyProtocol = WorldCupPollingFetchStrategy(),
         liveStrategy: WorldCupFetchStrategyProtocol = WorldCupPollingFetchStrategy(),
         teamsStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy(),
         logger: Logger = DefaultLogger.shared) throws {
        self.client = try WorldCupClient(config: config)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
        self.matchesStrategy = matchesStrategy
        self.liveStrategy = liveStrategy
        self.teamsStrategy = teamsStrategy
        self.usesDevServerTimeline = usesDevServerTimeline
        self.logger = logger
    }

    /// Convenience init that points the FFI at a custom host. Pass `nil` or
    /// an empty string to use the default merino host. Intended for local
    /// dev/beta testing against a non-production merino instance.
    convenience init(baseHost: String?,
                     matchesStrategy: WorldCupFetchStrategyProtocol = WorldCupPollingFetchStrategy(),
                     liveStrategy: WorldCupFetchStrategyProtocol = WorldCupPollingFetchStrategy(),
                     teamsStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy(),
                     logger: Logger = DefaultLogger.shared) throws {
        let trimmed = baseHost?.trimmingCharacters(in: .whitespacesAndNewlines)
        let host = (trimmed?.isEmpty == false) ? trimmed : nil
        try self.init(config: WorldCupConfig(baseHost: host),
                      usesDevServerTimeline: host != nil,
                      matchesStrategy: matchesStrategy,
                      liveStrategy: liveStrategy,
                      teamsStrategy: teamsStrategy,
                      logger: logger)
    }

    /// Low-level sync matches fetch + decode. Throws on FFI error or decode failure.
    /// Pass a 3-letter FIFA team key to filter the response to one team's fixtures.
    func fetchMatches(team: String? = nil) throws -> WorldCupMatchesResponse? {
        let requestID = String(UUID().uuidString.prefix(8))
        let start = Date()
        logger.log(
            "\(FreezeDiag.prefix)[WorldCupAPI] get_matches start id=\(requestID) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled) team=\(team ?? "<nil>")",
            level: .info,
            category: .homepage
        )
        do {
            let json = try client.getMatches(options: options(forTeam: team))
            let response = try decode(json, as: WorldCupMatchesResponse.self)
            let durationMs = FreezeDiag.durationMs(since: start)
            let level: LoggerLevel = durationMs > 3000 || Task.isCancelled ? .warning : .info
            logger.log(
                "\(FreezeDiag.prefix)[WorldCupAPI] get_matches end id=\(requestID) durationMs=\(durationMs) result=\(response == nil ? "successNil" : "success") matchCount=\(Self.matchCount(response)) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                level: level,
                category: .homepage
            )
            return response
        } catch {
            let durationMs = FreezeDiag.durationMs(since: start)
            logger.log(
                "\(FreezeDiag.prefix)[WorldCupAPI] get_matches end id=\(requestID) durationMs=\(durationMs) result=failure error=\(WorldCupLoadError.from(error)) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                level: .warning,
                category: .homepage
            )
            throw error
        }
    }

    /// Low-level sync live fetch + decode. Throws on FFI error or decode failure.
    /// Pass a 3-letter FIFA team key to filter the response to one team's fixtures.
    func fetchLive(team: String? = nil) throws -> WorldCupLiveResponse? {
        let requestID = String(UUID().uuidString.prefix(8))
        let start = Date()
        logger.log(
            "\(FreezeDiag.prefix)[WorldCupAPI] get_live start id=\(requestID) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled) team=\(team ?? "<nil>")",
            level: .info,
            category: .homepage
        )
        do {
            let json = try client.getLive(options: options(forTeam: team))
            let response = try decode(json, as: WorldCupLiveResponse.self)
            let durationMs = FreezeDiag.durationMs(since: start)
            let level: LoggerLevel = durationMs > 3000 || Task.isCancelled ? .warning : .info
            logger.log(
                "\(FreezeDiag.prefix)[WorldCupAPI] get_live end id=\(requestID) durationMs=\(durationMs) result=\(response == nil ? "successNil" : "success") matchCount=\(response?.matches?.count ?? 0) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                level: level,
                category: .homepage
            )
            return response
        } catch {
            let durationMs = FreezeDiag.durationMs(since: start)
            logger.log(
                "\(FreezeDiag.prefix)[WorldCupAPI] get_live end id=\(requestID) durationMs=\(durationMs) result=failure error=\(WorldCupLoadError.from(error)) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                level: .warning,
                category: .homepage
            )
            throw error
        }
    }

    /// Low-level sync teams fetch + decode. Throws on FFI error or decode failure.
    /// Pass a 3-letter FIFA team key to scope the roster response.
    func fetchTeams(team: String? = nil) throws -> WorldCupTeamsResponse? {
        let requestID = String(UUID().uuidString.prefix(8))
        let start = Date()
        logger.log(
            "\(FreezeDiag.prefix)[WorldCupAPI] get_teams start id=\(requestID) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled) team=\(team ?? "<nil>")",
            level: .info,
            category: .homepage
        )
        do {
            let json = try client.getTeams(options: options(forTeam: team))
            let response = try decode(json, as: WorldCupTeamsResponse.self)
            let durationMs = FreezeDiag.durationMs(since: start)
            let level: LoggerLevel = durationMs > 3000 || Task.isCancelled ? .warning : .info
            logger.log(
                "\(FreezeDiag.prefix)[WorldCupAPI] get_teams end id=\(requestID) durationMs=\(durationMs) result=\(response == nil ? "successNil" : "success") teamCount=\(response?.teams.count ?? 0) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                level: level,
                category: .homepage
            )
            return response
        } catch {
            let durationMs = FreezeDiag.durationMs(since: start)
            logger.log(
                "\(FreezeDiag.prefix)[WorldCupAPI] get_teams end id=\(requestID) durationMs=\(durationMs) result=failure error=\(WorldCupLoadError.from(error)) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                level: .warning,
                category: .homepage
            )
            throw error
        }
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

    private func options(forTeam team: String?) -> WorldCupOptions {
        // Dev mode: omit `date` so the mock uses its own simulated clock as
        // "today".
        let date = usesDevServerTimeline
            ? nil
            : Self.queryDateFormatter.string(from: max(Date(), Self.queryDateFloor))
        return WorldCupOptions(
            limit: nil,
            teams: team.map { [$0] },
            acceptLanguage: nil,
            date: date
        )
    }

    private func decode<T: Decodable>(_ json: String?, as type: T.Type) throws -> T? {
        guard let data = json?.data(using: .utf8) else { return nil }
        return try decoder.decode(type, from: data)
    }

    private static func matchCount(_ response: WorldCupMatchesResponse?) -> Int {
        guard let response else { return 0 }
        return (response.previous?.count ?? 0) + (response.current?.count ?? 0) + (response.next?.count ?? 0)
    }

    /// Builds the production-default client honoring two dev-only prefs:
    /// `WorldCupBaseHost` (custom merino host) and `WorldCupPollInterval`
    /// (override poll cadence in seconds). Returns `nil` if the FFI fails
    /// to initialize.
    static func makeDefault() -> WorldCupAPIClientProtocol? {
        let prefs = (AppContainer.shared.resolve() as Profile).prefs
        let baseHost = prefs.stringForKey(PrefsKeys.HomepageSettings.WorldCupBaseHost)
        let pollSeconds = prefs.intForKey(PrefsKeys.HomepageSettings.WorldCupPollInterval)
            .flatMap { $0 > 0 ? TimeInterval($0) : nil }
        let matchesConfig = pollSeconds
            .map { WorldCupPollingFetchStrategy.Config.matches.devOverridden(everySeconds: $0) }
            ?? .matches
        let liveConfig = pollSeconds
            .map { WorldCupPollingFetchStrategy.Config.live.devOverridden(everySeconds: $0) }
            ?? .live
        return try? WorldCupAPIClient(
            baseHost: baseHost,
            matchesStrategy: WorldCupPollingFetchStrategy(matchesConfig: matchesConfig,
                                                          liveConfig: liveConfig),
            liveStrategy: WorldCupPollingFetchStrategy(matchesConfig: matchesConfig,
                                                       liveConfig: liveConfig)
        )
    }
}
