// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

/// Drives the polling strategy's loop with a scripted mock client and a
/// delay-recording sleep, then asserts on the sequence of recorded delays.
/// Real wall-clock time never moves — the injected sleep just records and
/// returns immediately.
final class WorldCupPollingFetchStrategyTests: XCTestCase {
    // MARK: - Cadence after each result

    func test_consecutiveSuccess_keepsBaseInterval() async {
        let (results, scheduled) = await drive(
            config: config(base: 100, empty: 600, cap: 1200),
            scriptedResults: [.success(.populated), .success(.populated), .success(.populated)],
            collectCycles: 3
        )

        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(scheduled, [100, 100])
    }

    func test_consecutiveEmpty_doublesAndCaps() async {
        let (_, scheduled) = await drive(
            config: config(base: 60, empty: 100, cap: 250),
            scriptedResults: Array(repeating: .success(nil), count: 5),
            collectCycles: 5
        )

        XCTAssertEqual(scheduled, [100, 200, 250, 250])
    }

    func test_consecutiveFailure_doublesAndCaps() async {
        let (_, scheduled) = await drive(
            config: config(base: 100, empty: 600, cap: 250),
            scriptedResults: Array(repeating: .failure, count: 5),
            collectCycles: 5
        )

        XCTAssertEqual(scheduled, [100, 200, 250, 250])
    }

    // MARK: - Streak reset

    func test_successResetsErrorStreak() async {
        let (_, scheduled) = await drive(
            config: config(base: 100, empty: 600, cap: 1200),
            scriptedResults: [.failure, .failure, .success(.populated), .failure],
            collectCycles: 4
        )

        // fail → 100, fail → 200, success (resets) → 100, fail → 100 (errorStreak=1).
        XCTAssertEqual(scheduled, [100, 200, 100])
    }

    // MARK: - In-burst retry

    func test_inBurstRetry_recoversAndDeliversOneSuccess() async {
        let (results, allDelays) = await driveCollectingAllDelays(
            config: config(base: 100, empty: 600, cap: 1200,
                           errorRetries: 2, inBurstDelay: 1),
            scriptedResults: [.failure, .failure, .success(.populated)],
            collectCycles: 1
        )

        XCTAssertEqual(results.count, 1)
        // Two in-burst sleeps (1, 2) then the scheduled next-cycle delay (100).
        XCTAssertEqual(allDelays, [1, 2, 100])
    }

    func test_inBurstRetry_exhaustsAndDeliversFailure() async {
        let (results, allDelays) = await driveCollectingAllDelays(
            config: config(base: 100, empty: 600, cap: 1200,
                           errorRetries: 2, inBurstDelay: 1),
            scriptedResults: [.failure, .failure, .failure],
            collectCycles: 1
        )

        XCTAssertEqual(results.count, 1)
        if case .success = results[0] { XCTFail("expected failure") }
        XCTAssertEqual(allDelays, [1, 2, 100])
    }

    // MARK: - Helpers

    private func config(
        base: TimeInterval,
        empty: TimeInterval,
        cap: TimeInterval,
        errorRetries: Int = 0,
        inBurstDelay: TimeInterval = 0
    ) -> WorldCupPollingFetchStrategy.Config {
        WorldCupPollingFetchStrategy.Config(
            baseInterval: base,
            emptyCadence: empty,
            backoffCap: cap,
            errorRetries: errorRetries,
            inBurstDelay: inBurstDelay
        )
    }

    /// Runs the matches stream against scripted results, returning the
    /// emitted results and ONLY the scheduled inter-cycle delays (skipping
    /// in-burst retry delays). The last scheduled delay is dropped since it
    /// follows the final captured cycle.
    private func drive(
        config: WorldCupPollingFetchStrategy.Config,
        scriptedResults: [ScriptedResult],
        collectCycles: Int
    ) async -> (results: [Result<WorldCupMatchesResponse?, WorldCupLoadError>], scheduled: [TimeInterval]) {
        let (results, allDelays) = await driveCollectingAllDelays(
            config: config,
            scriptedResults: scriptedResults,
            collectCycles: collectCycles
        )
        // With errorRetries == 0, every recorded delay is a scheduled one.
        let scheduled = allDelays.dropLast()
        return (results, Array(scheduled))
    }

    private func driveCollectingAllDelays(
        config: WorldCupPollingFetchStrategy.Config,
        scriptedResults: [ScriptedResult],
        collectCycles: Int
    ) async -> (results: [Result<WorldCupMatchesResponse?, WorldCupLoadError>], delays: [TimeInterval]) {
        let delays = AsyncCollector<TimeInterval>()
        let results = AsyncCollector<Result<WorldCupMatchesResponse?, WorldCupLoadError>>()
        let sleep: @Sendable (TimeInterval) async -> Void = { delay in
            await delays.append(delay)
            await Task.yield()
        }
        let strategy = WorldCupPollingFetchStrategy(
            matchesConfig: config,
            liveConfig: config,
            sleep: sleep
        )
        let client = ScriptedMockClient(matchesScript: scriptedResults)

        let consumer = Task {
            for await result in strategy.matchesStream(using: client, team: nil) {
                await results.append(result)
            }
        }

        let collected = await results.collect(count: collectCycles)
        // Drain delays until we've captured at least one trailing scheduled
        // delay per cycle. For `errorRetries == 0` that's `collectCycles`
        // entries; the helper trims if more arrive in flight.
        let perCycleDelays = max(config.errorRetries + 1, 1)
        let recorded = await delays.collect(count: collectCycles * perCycleDelays)
        consumer.cancel()

        return (collected, recorded)
    }
}

// MARK: - Test support

private enum ScriptedResult {
    case success(Body)
    case failure

    enum Body {
        case empty
        case populated
    }
}

private final class ScriptedMockClient: WorldCupAPIClientProtocol, @unchecked Sendable {
    private let script: [ScriptedResult]
    private var index = 0

    init(matchesScript: [ScriptedResult]) {
        self.script = matchesScript
    }

    func fetchMatches(team: String?) throws -> WorldCupMatchesResponse? {
        let entry = script[min(index, script.count - 1)]
        index += 1
        switch entry {
        case .success(.empty): return nil
        case .success(.populated): return WorldCupMatchesResponse.singleMatch
        case .failure: throw MockWorldCupClientError.network
        }
    }

    func fetchLive(team: String?) throws -> WorldCupLiveResponse? { nil }
    func fetchTeams(team: String?) throws -> WorldCupTeamsResponse? { nil }

    func matchesStream(team: String?) -> WorldCupMatchesStream {
        AsyncStream { $0.finish() }
    }

    func liveStream(team: String?) -> WorldCupLiveStream {
        AsyncStream { $0.finish() }
    }

    func loadTeams(team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        .success(nil)
    }
}

private actor AsyncCollector<T: Sendable> {
    private var values: [T] = []
    private var waiters: [(Int, CheckedContinuation<[T], Never>)] = []

    func append(_ value: T) {
        values.append(value)
        let count = values.count
        let snapshot = values
        let ready = waiters.filter { $0.0 <= count }
        waiters.removeAll { $0.0 <= count }
        for (_, continuation) in ready {
            continuation.resume(returning: snapshot)
        }
    }

    func snapshot() -> [T] { values }

    func collect(count: Int) async -> [T] {
        if values.count >= count { return values }
        return await withCheckedContinuation { continuation in
            waiters.append((count, continuation))
        }
    }
}

private extension WorldCupMatchesResponse {
    static let singleMatch: WorldCupMatchesResponse = {
        let homeTeam = Team(key: "BRA", name: "Brazil", iconUrl: nil, group: "A", eliminated: false)
        let awayTeam = Team(key: "ARG", name: "Argentina", iconUrl: nil, group: "A", eliminated: false)
        let match = Match(
            date: "2026-06-12T18:00:00+00:00",
            globalEventId: 1,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            statusType: "scheduled"
        )
        return WorldCupMatchesResponse(previous: nil, current: [match], next: nil)
    }()
}
