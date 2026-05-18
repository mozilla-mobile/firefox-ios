// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupAPIClient")
struct WorldCupAPIClientTests {
    @Test
    func test_loadMatches_usesMatchesStrategy() async throws {
        let matchesStrategy = MockWorldCupFetchStrategy()
        let liveStrategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(matchesStrategy: matchesStrategy,
                                           liveStrategy: liveStrategy)

        _ = await client.loadMatches(team: nil)

        #expect(matchesStrategy.matchesCallCount == 1)
        #expect(liveStrategy.matchesCallCount == 0)
        #expect(liveStrategy.liveCallCount == 0)
    }

    @Test
    func test_loadLive_usesLiveStrategy() async throws {
        let matchesStrategy = MockWorldCupFetchStrategy()
        let liveStrategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(matchesStrategy: matchesStrategy,
                                           liveStrategy: liveStrategy)

        _ = await client.loadLive(team: nil)

        #expect(liveStrategy.liveCallCount == 1)
        #expect(matchesStrategy.liveCallCount == 0)
        #expect(matchesStrategy.matchesCallCount == 0)
    }

    @Test
    func test_loadMatches_returnsStrategyResult() async throws {
        let response = makeMatchesResponse()
        let strategy = MockWorldCupFetchStrategy(matchesResult: .success(response))
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        let result = await client.loadMatches(team: nil)

        #expect(result == .success(response))
    }

    @Test
    func test_loadMatches_returnsNil_whenStrategyReturnsNilSuccess() async throws {
        let strategy = MockWorldCupFetchStrategy(matchesResult: .success(nil))
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        let result = await client.loadMatches(team: nil)

        #expect(result == .success(nil))
    }

    @Test
    func test_loadMatches_propagatesStrategyFailure() async throws {
        let failure = WorldCupLoadError.network(reason: "offline")
        let strategy = MockWorldCupFetchStrategy(matchesResult: .failure(failure))
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        let result = await client.loadMatches(team: nil)

        #expect(result == .failure(failure))
    }

    @Test
    func test_loadMatches_forwardsTeam_toStrategy() async throws {
        let strategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        _ = await client.loadMatches(team: "BRA")

        #expect(strategy.lastMatchesTeam == "BRA")
    }

    @Test
    func test_loadLive_returnsStrategyResult() async throws {
        let response = makeLiveResponse()
        let strategy = MockWorldCupFetchStrategy(liveResult: .success(response))
        let client = try WorldCupAPIClient(liveStrategy: strategy)

        let result = await client.loadLive(team: nil)

        #expect(result == .success(response))
    }

    @Test
    func test_loadLive_forwardsTeam_toStrategy() async throws {
        let strategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(liveStrategy: strategy)

        _ = await client.loadLive(team: "BRA")

        #expect(strategy.lastLiveTeam == "BRA")
    }

    @Test
    func test_loadTeams_usesTeamsStrategy() async throws {
        let teamsStrategy = MockWorldCupFetchStrategy()
        let matchesStrategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(matchesStrategy: matchesStrategy,
                                           teamsStrategy: teamsStrategy)

        _ = await client.loadTeams(team: nil)

        #expect(teamsStrategy.teamsCallCount == 1)
        #expect(matchesStrategy.matchesCallCount == 0)
    }

    @Test
    func test_loadTeams_returnsStrategyResult() async throws {
        let response = makeTeamsResponse()
        let strategy = MockWorldCupFetchStrategy(teamsResult: .success(response))
        let client = try WorldCupAPIClient(teamsStrategy: strategy)

        let result = await client.loadTeams(team: nil)

        #expect(result == .success(response))
    }

    @Test
    func test_loadTeams_propagatesStrategyFailure() async throws {
        let failure = WorldCupLoadError.other(code: 500, reason: "server")
        let strategy = MockWorldCupFetchStrategy(teamsResult: .failure(failure))
        let client = try WorldCupAPIClient(teamsStrategy: strategy)

        let result = await client.loadTeams(team: nil)

        #expect(result == .failure(failure))
    }

    @Test
    func test_loadTeams_forwardsTeam_toStrategy() async throws {
        let strategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(teamsStrategy: strategy)

        _ = await client.loadTeams(team: "BRA")

        #expect(strategy.lastTeamsTeam == "BRA")
    }

    private func makeMatch() -> WorldCupMatchesResponse.Match {
        let homeTeam = WorldCupMatchesResponse.Team(
            key: "ENG",
            name: "England",
            iconUrl: nil,
            group: nil,
            eliminated: false
        )
        let awayTeam = WorldCupMatchesResponse.Team(
            key: "USA",
            name: "United States",
            iconUrl: nil,
            group: nil,
            eliminated: false
        )
        return WorldCupMatchesResponse.Match(
            date: "2026-05-11T14:00:00+00:00",
            globalEventId: 1,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            period: "2",
            homeScore: 1,
            awayScore: 0,
            homeExtra: nil,
            awayExtra: nil,
            homePenalty: nil,
            awayPenalty: nil,
            clock: "67",
            statusType: "live"
        )
    }

    private func makeMatchesResponse() -> WorldCupMatchesResponse {
        return WorldCupMatchesResponse(previous: nil, current: [makeMatch()], next: nil)
    }

    private func makeLiveResponse() -> WorldCupLiveResponse {
        return WorldCupLiveResponse(matches: [makeMatch()])
    }

    private func makeTeamsResponse() -> WorldCupTeamsResponse {
        WorldCupTeamsResponse(teams: [
            WorldCupTeamsResponse.Team(
                key: "BRA",
                globalTeamId: 1,
                name: "Brazil",
                region: "BRA",
                colors: nil,
                iconUrl: nil,
                group: "Group A",
                eliminated: false,
                standing: nil
            )
        ])
    }
}
