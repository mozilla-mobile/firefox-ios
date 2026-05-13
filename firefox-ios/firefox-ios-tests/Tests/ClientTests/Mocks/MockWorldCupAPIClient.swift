// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Foundation

enum MockWorldCupClientError: Error {
    case network
}

final class MockWorldCupAPIClient: WorldCupAPIClientProtocol, @unchecked Sendable {
    private let result: Result<WorldCupMatchesResponse?, Error>
    private let teamsResult: Result<WorldCupTeamsResponse?, Error>
    private(set) var fetchCount = 0
    private(set) var lastQuery: WorldCupQuery?
    private(set) var lastTeam: String?
    private(set) var fetchTeamsCount = 0
    private(set) var lastTeamsTeam: String?

    init(result: Result<WorldCupMatchesResponse?, Error>,
         teamsResult: Result<WorldCupTeamsResponse?, Error> = .success(nil)) {
        self.result = result
        self.teamsResult = teamsResult
    }

    func fetch(_ query: WorldCupQuery, team: String?) throws -> WorldCupMatchesResponse? {
        fetchCount += 1
        lastQuery = query
        lastTeam = team
        return try result.get()
    }

    func fetchTeams(team: String?) throws -> WorldCupTeamsResponse? {
        fetchTeamsCount += 1
        lastTeamsTeam = team
        return try teamsResult.get()
    }

    /// Not exercised by current callers — strategies call `fetch` directly.
    /// Provided to satisfy the protocol.
    func loadMatches(query: WorldCupQuery,
                     team: String?) async -> Result<WorldCupMatchesResponse?, WorldCupLoadError> {
        .success(nil)
    }

    /// Not exercised by current callers — strategies call `fetchTeams` directly.
    /// Provided to satisfy the protocol.
    func loadTeams(team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        .success(nil)
    }
}
