// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupAPIClient")
struct WorldCupAPIClientTests {
    @Test
    func test_loadMatches_withMatchesQuery_usesMatchesStrategy() async throws {
        let matchesStrategy = MockWorldCupFetchStrategy()
        let liveStrategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(matchesStrategy: matchesStrategy,
                                           liveStrategy: liveStrategy)

        _ = await client.loadMatches(query: .matches, team: nil)

        #expect(matchesStrategy.callCount == 1)
        #expect(matchesStrategy.lastQuery == .matches)
        #expect(liveStrategy.callCount == 0)
    }

    @Test
    func test_loadMatches_withLiveQuery_usesLiveStrategy() async throws {
        let matchesStrategy = MockWorldCupFetchStrategy()
        let liveStrategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(matchesStrategy: matchesStrategy,
                                           liveStrategy: liveStrategy)

        _ = await client.loadMatches(query: .live, team: nil)

        #expect(liveStrategy.callCount == 1)
        #expect(liveStrategy.lastQuery == .live)
        #expect(matchesStrategy.callCount == 0)
    }

    @Test
    func test_loadMatches_returnsStrategyResult() async throws {
        let response = makeResponse()
        let strategy = MockWorldCupFetchStrategy(result: .success(response))
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        let result = await client.loadMatches(query: .matches, team: nil)

        #expect(result == .success(response))
    }

    @Test
    func test_loadMatches_returnsNil_whenStrategyReturnsNilSuccess() async throws {
        let strategy = MockWorldCupFetchStrategy(result: .success(nil))
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        let result = await client.loadMatches(query: .matches, team: nil)

        #expect(result == .success(nil))
    }

    @Test
    func test_loadMatches_propagatesStrategyFailure() async throws {
        let failure = WorldCupLoadError.network(reason: "offline")
        let strategy = MockWorldCupFetchStrategy(result: .failure(failure))
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        let result = await client.loadMatches(query: .matches, team: nil)

        #expect(result == .failure(failure))
    }

    @Test
    func test_loadMatches_forwardsTeam_toStrategy() async throws {
        let strategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        _ = await client.loadMatches(query: .matches, team: "BRA")

        #expect(strategy.lastTeam == "BRA")
    }

    @Test
    func test_loadTeams_usesTeamsStrategy() async throws {
        let teamsStrategy = MockWorldCupFetchStrategy()
        let matchesStrategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(matchesStrategy: matchesStrategy,
                                           teamsStrategy: teamsStrategy)

        _ = await client.loadTeams(team: nil)

        #expect(teamsStrategy.teamsCallCount == 1)
        #expect(matchesStrategy.callCount == 0)
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

    private func makeResponse() -> WorldCupMatchesResponse {
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
        let match = WorldCupMatchesResponse.Match(
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
        return WorldCupMatchesResponse(previous: nil, current: [match], next: nil)
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
