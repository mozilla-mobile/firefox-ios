// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
import MozillaAppServices
@testable import Client

@Suite("WorldCupNormalFetchStrategy")
struct WorldCupFetchStrategyTests {
    @Test
    func test_returnsResponse_whenClientReturnsResponse() async {
        let fixture = makeResponse()
        let stub = MockWorldCupAPIClient(result: .success(fixture))
        let strategy = WorldCupNormalFetchStrategy()

        let response = await strategy.loadMatches(using: stub, query: .matches)

        #expect(response == fixture)
    }

    @Test
    func test_returnsNil_whenClientReturnsNil() async {
        let stub = MockWorldCupAPIClient(result: .success(nil))
        let strategy = WorldCupNormalFetchStrategy()

        let response = await strategy.loadMatches(using: stub, query: .matches)

        #expect(response == nil)
    }

    @Test
    func test_returnsNil_whenClientThrows() async {
        let stub = MockWorldCupAPIClient(result: .failure(MockWorldCupClientError.network))
        let strategy = WorldCupNormalFetchStrategy()

        let response = await strategy.loadMatches(using: stub, query: .matches)

        #expect(response == nil)
    }

    @Test
    func test_callsFetchExactlyOnce_onSuccess() async {
        let stub = MockWorldCupAPIClient(result: .success(makeResponse()))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, query: .matches)

        #expect(stub.fetchCount == 1)
    }

    @Test
    func test_doesNotRetry_onFailure() async {
        let stub = MockWorldCupAPIClient(result: .failure(MockWorldCupClientError.network))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, query: .matches)

        #expect(stub.fetchCount == 1)
    }

    @Test
    func test_forwardsQuery_toClient() async {
        let stub = MockWorldCupAPIClient(result: .success(makeResponse()))
        let strategy = WorldCupNormalFetchStrategy()

        _ = await strategy.loadMatches(using: stub, query: .live)

        #expect(stub.lastQuery == .live)
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
