// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

/// Single-attempt fetch strategy. Each stream yields exactly one result —
/// success / empty / failure — and finishes. No retry, no backoff. Maps any
/// thrown FFI/decode error into `WorldCupLoadError` so the UI can branch.
///
/// Useful for one-shot consumers (e.g. teams roster) and as a default in
/// tests that don't want polling cadence in the way.
struct WorldCupNormalFetchStrategy: WorldCupFetchStrategyProtocol {
    func matchesStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupMatchesStream {
        Self.singleShotStream(endpoint: "get_matches", team: team) { try client.fetchMatches(team: team) }
    }

    func liveStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupLiveStream {
        Self.singleShotStream(endpoint: "get_live", team: team) { try client.fetchLive(team: team) }
    }

    func loadTeams(using client: WorldCupAPIClientProtocol,
                   team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        await Self.singleAttempt(endpoint: "get_teams", team: team) { try client.fetchTeams(team: team) }
    }

    /// Runs the blocking FFI call off-main on a userInitiated detached task,
    /// then yields the mapped result once and finishes the stream.
    private static func singleShotStream<Response: Sendable>(
        endpoint: String,
        team: String?,
        _ fetch: @escaping @Sendable () throws -> Response?
    ) -> AsyncStream<Result<Response?, WorldCupLoadError>> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                let result = await singleAttempt(endpoint: endpoint, team: team, fetch)
                if !Task.isCancelled {
                    continuation.yield(result)
                } else {
                    DefaultLogger.shared.log(
                        "\(FreezeDiag.prefix)[WorldCupFetch] \(endpoint) completionAfterCancellation appState=\(FreezeDiag.applicationState) team=\(team ?? "<nil>") result=\(Self.resultSummary(result))",
                        level: .warning,
                        category: .homepage
                    )
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func singleAttempt<Response: Sendable>(
        endpoint: String = "unknown",
        team: String? = nil,
        _ fetch: @escaping @Sendable () throws -> Response?
    ) async -> Result<Response?, WorldCupLoadError> {
        await Task.detached(priority: .userInitiated) {
            () -> Result<Response?, WorldCupLoadError> in
            let requestID = String(UUID().uuidString.prefix(8))
            let start = Date()
            let logger = DefaultLogger.shared
            logger.log(
                "\(FreezeDiag.prefix)[WorldCupFetch] \(endpoint) attempt start id=\(requestID) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled) team=\(team ?? "<nil>")",
                level: .info,
                category: .homepage
            )
            do {
                let response = try fetch()
                let result: Result<Response?, WorldCupLoadError> = .success(response)
                let durationMs = FreezeDiag.durationMs(since: start)
                logger.log(
                    "\(FreezeDiag.prefix)[WorldCupFetch] \(endpoint) attempt end id=\(requestID) durationMs=\(durationMs) result=\(resultSummary(result)) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                    level: durationMs > 3000 || Task.isCancelled ? .warning : .info,
                    category: .homepage
                )
                return result
            } catch {
                let result: Result<Response?, WorldCupLoadError> = .failure(WorldCupLoadError.from(error))
                logger.log(
                    "\(FreezeDiag.prefix)[WorldCupFetch] \(endpoint) attempt end id=\(requestID) durationMs=\(FreezeDiag.durationMs(since: start)) result=\(resultSummary(result)) appState=\(FreezeDiag.applicationState) taskCancelled=\(Task.isCancelled)",
                    level: .warning,
                    category: .homepage
                )
                return result
            }
        }.value
    }

    private static func resultSummary<Response>(_ result: Result<Response?, WorldCupLoadError>) -> String {
        switch result {
        case .success(.some):
            return "success"
        case .success(.none):
            return "successNil"
        case .failure(let error):
            return "failure(\(error))"
        }
    }
}
