// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupNormalFetchStrategy")
struct WorldCupFetchStrategyTests {
    @Test
    func test_loadMatches_returnsSuccess_whenClientReturnsResponse() async {
        let fixture = makeMatchesResponse()
        let stub = MockWorldCupAPIClient(matchesResult: .success(fixture))
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadMatches(using: stub, team: nil)

        #expect(result == .success(fixture))
    }

    @Test
    func test_loadMatches_returnsSuccessNil_whenClientReturnsNil() async {
        let stub = MockWorldCupAPIClient(matchesResult: .success(nil))
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadMatches(using: stub, team: nil)

        #expect(result == .success(nil))
    }

    @Test
    func test_loadMatches_returnsFailure_whenClientThrows() async {
        let stub = MockWorldCupAPIClient(matchesResult: .failure(MockWorldCupClientError.network))
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadMatches(using: stub, team: nil)

        #expect(result == .failure(.other(code: nil, reason: "network")))
    }

    @Test
    func test_loadMatches_callsFetchExactlyOnce_onSuccess() async {
        let stub = MockWorldCupAPIClient(matchesResult: .success(makeMatchesResponse()))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, team: nil)

        #expect(stub.matchesFetchCount == 1)
    }

    @Test
    func test_loadMatches_doesNotRetry_onFailure() async {
        let stub = MockWorldCupAPIClient(matchesResult: .failure(MockWorldCupClientError.network))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, team: nil)

        #expect(stub.matchesFetchCount == 1)
    }

    @Test
    func test_loadMatches_forwardsTeam_toClient() async {
        let stub = MockWorldCupAPIClient(matchesResult: .success(makeMatchesResponse()))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, team: "BRA")

        #expect(stub.lastMatchesTeam == "BRA")
    }

    @Test
    func test_loadLive_callsFetchLive_andReturnsResponse() async {
        let fixture = makeLiveResponse()
        let stub = MockWorldCupAPIClient(
            matchesResult: .success(nil),
            liveResult: .success(fixture)
        )
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadLive(using: stub, team: nil)

        #expect(result == .success(fixture))
        #expect(stub.liveFetchCount == 1)
        #expect(stub.matchesFetchCount == 0)
    }

    @Test
    func test_loadLive_forwardsTeam_toClient() async {
        let stub = MockWorldCupAPIClient(
            matchesResult: .success(nil),
            liveResult: .success(makeLiveResponse())
        )
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadLive(using: stub, team: "BRA")

        #expect(stub.lastLiveTeam == "BRA")
    }

    @Test
    func test_loadTeams_returnsSuccess_whenClientReturnsResponse() async {
        let fixture = makeTeamsResponse()
        let stub = MockWorldCupAPIClient(matchesResult: .success(nil), teamsResult: .success(fixture))
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadTeams(using: stub, team: nil)

        #expect(result == .success(fixture))
    }

    @Test
    func test_loadTeams_returnsFailure_whenClientThrows() async {
        let stub = MockWorldCupAPIClient(
            matchesResult: .success(nil),
            teamsResult: .failure(MockWorldCupClientError.network)
        )
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadTeams(using: stub, team: nil)

        #expect(result == .failure(.other(code: nil, reason: "network")))
    }

    @Test
    func test_loadTeams_callsFetchTeamsExactlyOnce_onSuccess() async {
        let stub = MockWorldCupAPIClient(
            matchesResult: .success(nil),
            teamsResult: .success(makeTeamsResponse())
        )
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadTeams(using: stub, team: nil)

        #expect(stub.fetchTeamsCount == 1)
    }

    @Test
    func test_loadTeams_forwardsTeam_toClient() async {
        let stub = MockWorldCupAPIClient(
            matchesResult: .success(nil),
            teamsResult: .success(makeTeamsResponse())
        )
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadTeams(using: stub, team: "BRA")

        #expect(stub.lastTeamsTeam == "BRA")
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
        WorldCupMatchesResponse(previous: nil, current: [makeMatch()], next: nil)
    }

    private func makeLiveResponse() -> WorldCupLiveResponse {
        WorldCupLiveResponse(matches: [makeMatch()])
    }
}
