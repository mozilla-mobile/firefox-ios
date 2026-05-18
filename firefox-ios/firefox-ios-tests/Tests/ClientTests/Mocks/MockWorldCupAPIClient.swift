// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Foundation

enum MockWorldCupClientError: Error {
    case network
}

final class MockWorldCupAPIClient: WorldCupAPIClientProtocol, @unchecked Sendable {
    private let matchesResult: Result<WorldCupMatchesResponse?, Error>
    private let liveResult: Result<WorldCupLiveResponse?, Error>
    private let teamsResult: Result<WorldCupTeamsResponse?, Error>
    private(set) var matchesFetchCount = 0
    private(set) var liveFetchCount = 0
    private(set) var fetchTeamsCount = 0
    private(set) var lastMatchesTeam: String?
    private(set) var lastLiveTeam: String?
    private(set) var lastTeamsTeam: String?

    init(matchesResult: Result<WorldCupMatchesResponse?, Error>,
         liveResult: Result<WorldCupLiveResponse?, Error> = .success(nil),
         teamsResult: Result<WorldCupTeamsResponse?, Error> = .success(nil)) {
        self.matchesResult = matchesResult
        self.liveResult = liveResult
        self.teamsResult = teamsResult
    }

    func fetchMatches(team: String?) throws -> WorldCupMatchesResponse? {
        matchesFetchCount += 1
        lastMatchesTeam = team
        return try matchesResult.get()
    }

    func fetchLive(team: String?) throws -> WorldCupLiveResponse? {
        liveFetchCount += 1
        lastLiveTeam = team
        return try liveResult.get()
    }

    func fetchTeams(team: String?) throws -> WorldCupTeamsResponse? {
        fetchTeamsCount += 1
        lastTeamsTeam = team
        return try teamsResult.get()
    }

    /// Emits the canned matches result once and finishes. Tests that want
    /// polling semantics should pass a real `WorldCupPollingFetchStrategy`
    /// and wire the mock client into it.
    func matchesStream(team: String?) -> WorldCupMatchesStream {
        let captured = matchesResult
        let recordTeam: @Sendable () -> Void = { [weak self] in
            self?.lastMatchesTeam = team
            self?.matchesFetchCount += 1
        }
        return AsyncStream { continuation in
            Task {
                recordTeam()
                continuation.yield(Self.mapped(captured))
                continuation.finish()
            }
        }
    }

    /// Emits the canned live result once and finishes.
    func liveStream(team: String?) -> WorldCupLiveStream {
        let captured = liveResult
        let recordTeam: @Sendable () -> Void = { [weak self] in
            self?.lastLiveTeam = team
            self?.liveFetchCount += 1
        }
        return AsyncStream { continuation in
            Task {
                recordTeam()
                continuation.yield(Self.mapped(captured))
                continuation.finish()
            }
        }
    }

    func loadTeams(team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        lastTeamsTeam = team
        switch teamsResult {
        case .success(let response): return .success(response)
        case .failure(let error):    return .failure(WorldCupLoadError.from(error))
        }
    }

    private static func mapped<Response>(
        _ result: Result<Response?, Error>
    ) -> Result<Response?, WorldCupLoadError> {
        switch result {
        case .success(let value): return .success(value)
        case .failure(let error): return .failure(WorldCupLoadError.from(error))
        }
    }
}
