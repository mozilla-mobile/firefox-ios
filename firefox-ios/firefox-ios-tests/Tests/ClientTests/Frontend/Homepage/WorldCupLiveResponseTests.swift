// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupLiveResponse decoding")
struct WorldCupLiveResponseTests {
    // Representative payload modeled after the merino WCS /live fixture:
    // a flat `matches` array (not the previous/current/next buckets of /matches).
    // Verifies snake_case -> camelCase decoding and that nullable score fields
    // decode cleanly for in-progress vs finished matches.
    private let json = """
    {
      "matches": [{
        "date": "2026-05-17T13:00:00+00:00",
        "global_event_id": 1020,
        "home_team": {
          "key": "USA", "global_team_id": 90000872, "name": "United States", "region": "USA",
          "colors": ["#B22234","#FFFFFF","#3C3B6E"], "icon_url": "https://example.com/usa.svg",
          "group": "Group D", "eliminated": false
        },
        "away_team": {
          "key": "ENG", "global_team_id": 90000858, "name": "England", "region": "ENG",
          "colors": ["#FFFFFF","#CE1126"], "icon_url": "https://example.com/eng.svg",
          "group": "Group L", "eliminated": false
        },
        "period": "FT", "home_score": 3, "away_score": 0,
        "home_extra": null, "away_extra": null,
        "home_penalty": null, "away_penalty": null,
        "clock": "90", "updated": 1779019200, "stage": null,
        "status": "Awarded", "status_type": "past", "query": null, "sport": "soccer"
      }, {
        "date": "2026-05-17T18:00:00+00:00",
        "global_event_id": 1002,
        "home_team": {
          "key": "GER", "global_team_id": 90000947, "name": "Germany", "region": "GER",
          "colors": [], "icon_url": null, "group": "Group E", "eliminated": false
        },
        "away_team": {
          "key": "FRA", "global_team_id": 90000946, "name": "France", "region": "FRA",
          "colors": [], "icon_url": null, "group": "Group I", "eliminated": false
        },
        "period": "FT(P)", "home_score": 1, "away_score": 1,
        "home_extra": 1, "away_extra": 1,
        "home_penalty": 5, "away_penalty": 4,
        "clock": "120", "updated": 1779037200, "stage": null,
        "status": "Final", "status_type": "past", "query": null, "sport": "soccer"
      }]
    }
    """

    @Test
    func test_decodesMatchesArray() throws {
        let response = try decode(json)

        #expect(response.matches?.count == 2)

        let first = try #require(response.matches?.first)
        #expect(first.homeTeam.key == "USA")
        #expect(first.awayTeam.key == "ENG")
        #expect(first.homeScore == 3)
        #expect(first.awayScore == 0)
        #expect(first.clock == "90")
        #expect(first.statusType == "past")
        #expect(first.homeTeam.iconUrl == "https://example.com/usa.svg")
    }

    @Test
    func test_decodesPenaltyShootout() throws {
        let response = try decode(json)
        let second = try #require(response.matches?.last)

        #expect(second.homeExtra == 1)
        #expect(second.awayExtra == 1)
        #expect(second.homePenalty == 5)
        #expect(second.awayPenalty == 4)
        #expect(second.period == "FT(P)")
    }

    @Test
    func test_decodesEmptyMatchesArray() throws {
        let response = try decode(#"{ "matches": [] }"#)
        #expect(response.matches?.isEmpty == true)
    }

    @Test
    func test_decodesEmptyTopLevelObject() throws {
        let response = try decode("{}")
        #expect(response.matches == nil)
    }

    @Test
    func test_decodesIgnoresUnknownTopLevelKeys() throws {
        let response = try decode(#"{ "matches": [], "unknown_field": "ignored", "extra": 42 }"#)
        #expect(response.matches?.isEmpty == true)
    }

    @Test
    func test_responseEquality_sameContent() {
        let responseA = WorldCupLiveResponse(matches: [])
        let responseB = WorldCupLiveResponse(matches: [])
        #expect(responseA == responseB)
    }

    @Test
    func test_responseEquality_nilVsEmpty() {
        let responseA = WorldCupLiveResponse(matches: nil)
        let responseB = WorldCupLiveResponse(matches: [])
        #expect(responseA != responseB)
    }

    @Test
    func test_responseEquality_differentMatches() {
        let team = WorldCupMatchesResponse.Team(
            key: "ENG",
            name: "England",
            iconUrl: nil,
            group: nil,
            eliminated: false
        )
        let matchA = WorldCupMatchesResponse.Match(
            date: "2026-05-11T14:00:00+00:00",
            globalEventId: 1,
            homeTeam: team,
            awayTeam: team
        )
        let matchB = WorldCupMatchesResponse.Match(
            date: "2026-05-11T14:00:00+00:00",
            globalEventId: 2,
            homeTeam: team,
            awayTeam: team
        )
        #expect(WorldCupLiveResponse(matches: [matchA]) != WorldCupLiveResponse(matches: [matchB]))
    }

    private func decode(_ json: String) throws -> WorldCupLiveResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WorldCupLiveResponse.self, from: Data(json.utf8))
    }
}
