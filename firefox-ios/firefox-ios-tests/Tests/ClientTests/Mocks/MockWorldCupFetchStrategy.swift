// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Foundation

final class MockWorldCupFetchStrategy: WorldCupFetchStrategyProtocol, @unchecked Sendable {
    private let matchesResult: Result<WorldCupMatchesResponse?, WorldCupLoadError>
    private let teamsResult: Result<WorldCupTeamsResponse?, WorldCupLoadError>
    private(set) var callCount = 0
    private(set) var lastQuery: WorldCupQuery?
    private(set) var lastTeam: String?
    private(set) var teamsCallCount = 0
    private(set) var lastTeamsTeam: String?

    init(result: Result<WorldCupMatchesResponse?, WorldCupLoadError> = .success(nil),
         teamsResult: Result<WorldCupTeamsResponse?, WorldCupLoadError> = .success(nil)) {
        self.matchesResult = result
        self.teamsResult = teamsResult
    }

    func loadMatches(using client: WorldCupAPIClientProtocol,
                     query: WorldCupQuery,
                     team: String?) async -> Result<WorldCupMatchesResponse?, WorldCupLoadError> {
        callCount += 1
        lastQuery = query
        lastTeam = team
        return matchesResult
    }

    func loadTeams(using client: WorldCupAPIClientProtocol,
                   team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        teamsCallCount += 1
        lastTeamsTeam = team
        return teamsResult
    }
}
