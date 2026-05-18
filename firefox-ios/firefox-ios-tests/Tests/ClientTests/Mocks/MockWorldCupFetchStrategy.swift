// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Foundation

/// Test double that yields the configured result once on each stream and
/// finishes. Used by `WorldCupAPIClientTests` to verify call routing without
/// running the real polling/backoff loop.
final class MockWorldCupFetchStrategy: WorldCupFetchStrategyProtocol, @unchecked Sendable {
    private let matchesResult: Result<WorldCupMatchesResponse?, WorldCupLoadError>
    private let liveResult: Result<WorldCupLiveResponse?, WorldCupLoadError>
    private let teamsResult: Result<WorldCupTeamsResponse?, WorldCupLoadError>
    private(set) var matchesCallCount = 0
    private(set) var liveCallCount = 0
    private(set) var teamsCallCount = 0
    private(set) var lastMatchesTeam: String?
    private(set) var lastLiveTeam: String?
    private(set) var lastTeamsTeam: String?

    init(matchesResult: Result<WorldCupMatchesResponse?, WorldCupLoadError> = .success(nil),
         liveResult: Result<WorldCupLiveResponse?, WorldCupLoadError> = .success(nil),
         teamsResult: Result<WorldCupTeamsResponse?, WorldCupLoadError> = .success(nil)) {
        self.matchesResult = matchesResult
        self.liveResult = liveResult
        self.teamsResult = teamsResult
    }

    func matchesStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupMatchesStream {
        matchesCallCount += 1
        lastMatchesTeam = team
        let result = matchesResult
        return AsyncStream { continuation in
            continuation.yield(result)
            continuation.finish()
        }
    }

    func liveStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupLiveStream {
        liveCallCount += 1
        lastLiveTeam = team
        let result = liveResult
        return AsyncStream { continuation in
            continuation.yield(result)
            continuation.finish()
        }
    }

    func loadTeams(using client: WorldCupAPIClientProtocol,
                   team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        teamsCallCount += 1
        lastTeamsTeam = team
        return teamsResult
    }
}
