// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Single-attempt fetch strategy. Each stream yields exactly one result —
/// success / empty / failure — and finishes. No retry, no backoff. Maps any
/// thrown FFI/decode error into `WorldCupLoadError` so the UI can branch.
///
/// Useful for one-shot consumers (e.g. teams roster) and as a default in
/// tests that don't want polling cadence in the way.
struct WorldCupNormalFetchStrategy: WorldCupFetchStrategyProtocol {
    func matchesStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupMatchesStream {
        Self.singleShotStream { try client.fetchMatches(team: team) }
    }

    func liveStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupLiveStream {
        Self.singleShotStream { try client.fetchLive(team: team) }
    }

    func loadTeams(using client: WorldCupAPIClientProtocol,
                   team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        await Self.singleAttempt { try client.fetchTeams(team: team) }
    }

    /// Runs the blocking FFI call off-main on a userInitiated detached task,
    /// then yields the mapped result once and finishes the stream.
    private static func singleShotStream<Response: Sendable>(
        _ fetch: @escaping @Sendable () throws -> Response?
    ) -> AsyncStream<Result<Response?, WorldCupLoadError>> {
        AsyncStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                let result = await singleAttempt(fetch)
                if !Task.isCancelled {
                    continuation.yield(result)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    static func singleAttempt<Response: Sendable>(
        _ fetch: @escaping @Sendable () throws -> Response?
    ) async -> Result<Response?, WorldCupLoadError> {
        await Task.detached(priority: .userInitiated) {
            () -> Result<Response?, WorldCupLoadError> in
            do {
                return .success(try fetch())
            } catch {
                return .failure(WorldCupLoadError.from(error))
            }
        }.value
    }
}
