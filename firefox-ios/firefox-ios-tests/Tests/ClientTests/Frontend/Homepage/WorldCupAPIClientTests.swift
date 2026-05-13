// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
import MozillaAppServices
@testable import Client

@Suite("WorldCupAPIClient")
struct WorldCupAPIClientTests {
    @Test
    func test_loadMatches_withMatchesQuery_usesMatchesStrategy() async throws {
        let matchesStrategy = MockWorldCupFetchStrategy()
        let liveStrategy = MockWorldCupFetchStrategy()
        let client = try WorldCupAPIClient(matchesStrategy: matchesStrategy,
                                           liveStrategy: liveStrategy)

        _ = await client.loadMatches(query: .matches)

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

        _ = await client.loadMatches(query: .live)

        #expect(liveStrategy.callCount == 1)
        #expect(liveStrategy.lastQuery == .live)
        #expect(matchesStrategy.callCount == 0)
    }

    @Test
    func test_loadMatches_returnsStrategyResult() async throws {
        let response = makeResponse()
        let strategy = MockWorldCupFetchStrategy(result: response)
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        let result = await client.loadMatches(query: .matches)

        #expect(result == response)
    }

    @Test
    func test_loadMatches_returnsNil_whenStrategyReturnsNil() async throws {
        let strategy = MockWorldCupFetchStrategy(result: nil)
        let client = try WorldCupAPIClient(matchesStrategy: strategy)

        let result = await client.loadMatches(query: .matches)

        #expect(result == nil)
    }

    @Test
    func test_emptyOptions_hasAllNilFields() {
        let options = WorldCupAPIClient.emptyOptions
        #expect(options.limit == nil)
        #expect(options.teams == nil)
        #expect(options.acceptLanguage == nil)
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
}
