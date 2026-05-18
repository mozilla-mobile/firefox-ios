// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Polls the WCS endpoints on a fixed cadence with three independent
/// behaviors layered on top:
///
/// - **In-burst retry on `failure`.** A single fetch failure triggers up to
///   `errorRetries` short retries (linearly-growing delay) before the result
///   is emitted. The next scheduled tick still fires regardless.
/// - **Exponential backoff on `success(.none)` (HTTP 204).** 204 is the
///   common case for `/live` between matches and for `/matches` outside the
///   tournament window. Backing off avoids hammering merino for content it
///   doesn't have.
/// - **Exponential backoff on `failure`.** Errors that survive the in-burst
///   retry double the next-cycle delay until `backoffCap`.
///
/// All exponentials are clamped to `backoffCap` so a stuck state always
/// recovers without external intervention. State (streaks, in-flight task)
/// lives entirely inside the `AsyncStream`'s producer Task — no locks, no
/// shared mutable state.
///
/// Teams are still one-shot, so `loadTeams` delegates to a single-attempt
/// strategy.
struct WorldCupPollingFetchStrategy: WorldCupFetchStrategyProtocol {
    struct Config: Sendable {
        let baseInterval: TimeInterval
        let emptyCadence: TimeInterval
        let backoffCap: TimeInterval
        let errorRetries: Int
        let inBurstDelay: TimeInterval

        /// 15-minute cadence. `/matches` only needs to refresh for events
        /// that happen every few minutes at most: match finalization, day
        /// rollover, knockout bracket fills. Live scores arrive via `/live`
        /// at a faster cadence. On 204 seed the empty backoff at 10 minutes;
        /// on error, two short in-burst retries before falling back to the
        /// schedule. Everything capped at 20 minutes.
        static let matches = Config(
            baseInterval: 900,
            emptyCadence: 600,
            backoffCap: 1200,
            errorRetries: 2,
            inBurstDelay: 2
        )

        /// 3-minute cadence. One quick in-burst retry on error before falling
        /// back to exponential backoff. 204 is expected outside live windows,
        /// so seed the empty backoff at 10 minutes rather than the base
        /// interval. Capped at 20 minutes.
        static let live = Config(
            baseInterval: 180,
            emptyCadence: 600,
            backoffCap: 1200,
            errorRetries: 1,
            inBurstDelay: 2
        )

        /// Returns a copy where `baseInterval`, `emptyCadence`, and `backoffCap`
        /// are all clamped to `seconds`. Intended for dev/QA — lets you fire a
        /// poll every N seconds regardless of result type, so you don't have
        /// to wait for the production cadence to inspect live behavior.
        func devOverridden(everySeconds seconds: TimeInterval) -> Config {
            Config(
                baseInterval: seconds,
                emptyCadence: seconds,
                backoffCap: seconds,
                errorRetries: errorRetries,
                inBurstDelay: inBurstDelay
            )
        }
    }

    typealias Sleep = @Sendable (TimeInterval) async -> Void

    let matchesConfig: Config
    let liveConfig: Config
    let sleep: Sleep
    /// Teams are one-shot so we delegate to a single-attempt strategy rather
    /// than reinvent the wheel.
    let teamsStrategy: WorldCupFetchStrategyProtocol

    init(
        matchesConfig: Config = .matches,
        liveConfig: Config = .live,
        sleep: @escaping Sleep = { try? await Task.sleep(nanoseconds: UInt64($0 * 1_000_000_000)) },
        teamsStrategy: WorldCupFetchStrategyProtocol = WorldCupNormalFetchStrategy()
    ) {
        self.matchesConfig = matchesConfig
        self.liveConfig = liveConfig
        self.sleep = sleep
        self.teamsStrategy = teamsStrategy
    }

    func matchesStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupMatchesStream {
        makeStream(config: matchesConfig) { try client.fetchMatches(team: team) }
    }

    func liveStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupLiveStream {
        makeStream(config: liveConfig) { try client.fetchLive(team: team) }
    }

    func loadTeams(using client: WorldCupAPIClientProtocol,
                   team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        await teamsStrategy.loadTeams(using: client, team: team)
    }

    private func makeStream<Response: Sendable>(
        config: Config,
        fetch: @escaping @Sendable () throws -> Response?
    ) -> AsyncStream<Result<Response?, WorldCupLoadError>> {
        let sleep = self.sleep
        return AsyncStream { continuation in
            let task = Task.detached(priority: .userInitiated) {
                var emptyStreak = 0
                var errorStreak = 0
                while !Task.isCancelled {
                    let result = await attemptWithBurstRetry(
                        config: config,
                        sleep: sleep,
                        fetch: fetch
                    )
                    if Task.isCancelled { break }
                    continuation.yield(result)
                    let delay = nextDelay(
                        after: result,
                        config: config,
                        emptyStreak: &emptyStreak,
                        errorStreak: &errorStreak
                    )
                    await sleep(delay)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

/// Runs the fetch up to `errorRetries + 1` times within a single cycle,
/// returning the last result. Each in-burst retry waits `inBurstDelay * n`
/// (so 1× then 2× then 3× …) — short enough that the user doesn't notice,
/// long enough to ride out a transient blip.
private func attemptWithBurstRetry<Response: Sendable>(
    config: WorldCupPollingFetchStrategy.Config,
    sleep: WorldCupPollingFetchStrategy.Sleep,
    fetch: @escaping @Sendable () throws -> Response?
) async -> Result<Response?, WorldCupLoadError> {
    var attempt = 0
    while true {
        let result = await WorldCupNormalFetchStrategy.singleAttempt(fetch)
        if case .failure = result,
           attempt < config.errorRetries,
           !Task.isCancelled {
            attempt += 1
            await sleep(config.inBurstDelay * Double(attempt))
            continue
        }
        return result
    }
}

/// Picks the delay before the next attempt based on the just-returned result
/// and updates the appropriate streak. `success(.some)` resets both streaks;
/// `success(.none)` and `failure` each grow their own streak, so alternating
/// empties and errors don't compound.
private func nextDelay<Response>(
    after result: Result<Response?, WorldCupLoadError>,
    config: WorldCupPollingFetchStrategy.Config,
    emptyStreak: inout Int,
    errorStreak: inout Int
) -> TimeInterval {
    switch result {
    case .success(.some):
        emptyStreak = 0
        errorStreak = 0
        return config.baseInterval
    case .success(.none):
        errorStreak = 0
        emptyStreak += 1
        let raw = config.emptyCadence * pow(2.0, Double(emptyStreak - 1))
        return min(raw, config.backoffCap)
    case .failure:
        emptyStreak = 0
        errorStreak += 1
        let raw = config.baseInterval * pow(2.0, Double(errorStreak - 1))
        return min(raw, config.backoffCap)
    }
}
