// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupNormalFetchStrategy")
struct WorldCupFetchStrategyTests {
    @Test
    func test_returnsSuccess_whenClientReturnsResponse() async {
        let fixture = makeResponse()
        let stub = MockWorldCupAPIClient(result: .success(fixture))
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadMatches(using: stub, query: .matches, team: nil)

        #expect(result == .success(fixture))
    }

    @Test
    func test_returnsSuccessNil_whenClientReturnsNil() async {
        let stub = MockWorldCupAPIClient(result: .success(nil))
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadMatches(using: stub, query: .matches, team: nil)

        #expect(result == .success(nil))
    }

    @Test
    func test_returnsFailure_whenClientThrows() async {
        let stub = MockWorldCupAPIClient(result: .failure(MockWorldCupClientError.network))
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadMatches(using: stub, query: .matches, team: nil)

        #expect(result == .failure(.other(code: nil, reason: "network")))
    }

    @Test
    func test_callsFetchExactlyOnce_onSuccess() async {
        let stub = MockWorldCupAPIClient(result: .success(makeResponse()))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, query: .matches, team: nil)

        #expect(stub.fetchCount == 1)
    }

    @Test
    func test_doesNotRetry_onFailure() async {
        let stub = MockWorldCupAPIClient(result: .failure(MockWorldCupClientError.network))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, query: .matches, team: nil)

        #expect(stub.fetchCount == 1)
    }

    @Test
    func test_forwardsQuery_toClient() async {
        let stub = MockWorldCupAPIClient(result: .success(makeResponse()))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, query: .live, team: nil)

        #expect(stub.lastQuery == .live)
    }

    @Test
    func test_forwardsTeam_toClient() async {
        let stub = MockWorldCupAPIClient(result: .success(makeResponse()))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, query: .matches, team: "BRA")

        #expect(stub.lastTeam == "BRA")
    }

    @Test
    func test_loadTeams_returnsSuccess_whenClientReturnsResponse() async {
        let fixture = makeTeamsResponse()
        let stub = MockWorldCupAPIClient(result: .success(nil), teamsResult: .success(fixture))
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadTeams(using: stub, team: nil)

        #expect(result == .success(fixture))
    }

    @Test
    func test_loadTeams_returnsFailure_whenClientThrows() async {
        let stub = MockWorldCupAPIClient(
            result: .success(nil),
            teamsResult: .failure(MockWorldCupClientError.network)
        )
        let strategy = WorldCupNormalFetchStrategy()

        let result = await strategy.loadTeams(using: stub, team: nil)

        #expect(result == .failure(.other(code: nil, reason: "network")))
    }

    @Test
    func test_loadTeams_callsFetchTeamsExactlyOnce_onSuccess() async {
        let stub = MockWorldCupAPIClient(
            result: .success(nil),
            teamsResult: .success(makeTeamsResponse())
        )
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadTeams(using: stub, team: nil)

        #expect(stub.fetchTeamsCount == 1)
    }

    @Test
    func test_loadTeams_forwardsTeam_toClient() async {
        let stub = MockWorldCupAPIClient(
            result: .success(nil),
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

        return WorldCupMatchesResponse(
            previous: nil,
            current: [
                WorldCupMatchesResponse.Match(
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
            ],
            next: nil
        )
    }
}
