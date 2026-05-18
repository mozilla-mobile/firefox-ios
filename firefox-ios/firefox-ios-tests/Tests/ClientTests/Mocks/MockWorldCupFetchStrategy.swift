// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Foundation

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

    func loadMatches(using client: WorldCupAPIClientProtocol,
                     team: String?) async -> Result<WorldCupMatchesResponse?, WorldCupLoadError> {
        matchesCallCount += 1
        lastMatchesTeam = team
        return matchesResult
    }

    func loadLive(using client: WorldCupAPIClientProtocol,
                  team: String?) async -> Result<WorldCupLiveResponse?, WorldCupLoadError> {
        liveCallCount += 1
        lastLiveTeam = team
        return liveResult
    }

    func loadTeams(using client: WorldCupAPIClientProtocol,
                   team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        teamsCallCount += 1
        lastTeamsTeam = team
        return teamsResult
    }
}
