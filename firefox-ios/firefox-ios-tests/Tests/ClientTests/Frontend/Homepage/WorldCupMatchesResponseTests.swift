// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupMatchesResponse decoding")
struct WorldCupMatchesResponseTests {
    // Representative payload modeled after the merino WCS fixture: one live match
    // (with PK fields), one scheduled match (with null scores). Verifies snake_case
    // -> camelCase decoding and that null-vs-missing optional fields decode cleanly.
    private let json = """
    {
      "current": [{
        "date": "2026-04-30T14:00:00+00:00",
        "global_event_id": 1002,
        "home_team": {
          "key": "ENG", "global_team_id": 5, "name": "England", "region": "ENG",
          "colors": ["White","Red"], "icon_url": "https://example.com/eng.png",
          "group": "Group C", "eliminated": false,
          "standing": {"wins":0,"losses":0,"draws":0,"points":0}
        },
        "away_team": {
          "key": "USA", "global_team_id": 6, "name": "United States", "region": "USA",
          "colors": ["Navy","White","Red"], "icon_url": "https://example.com/usa.png",
          "group": "Group C", "eliminated": false,
          "standing": {"wins":0,"losses":0,"draws":0,"points":0}
        },
        "period": "2", "home_score": 1, "away_score": 0,
        "home_extra": null, "away_extra": null,
        "home_penalty": null, "away_penalty": null,
        "clock": "67", "updated": 1, "status": "In Progress",
        "status_type": "live", "query": null, "sport": "soccer"
      }],
      "next": [{
        "date": "2026-05-01T15:00:00+00:00",
        "global_event_id": 1004,
        "home_team": {
          "key": "ARG", "global_team_id": 2, "name": "Argentina", "region": "ARG",
          "colors": [], "icon_url": null, "group": "Group A", "eliminated": false,
          "standing": {"wins":0,"losses":0,"draws":0,"points":0}
        },
        "away_team": {
          "key": "ENG", "global_team_id": 5, "name": "England", "region": "ENG",
          "colors": [], "icon_url": null, "group": "Group C", "eliminated": false,
          "standing": {"wins":0,"losses":0,"draws":0,"points":0}
        },
        "period": "1", "home_score": null, "away_score": null,
        "home_extra": null, "away_extra": null,
        "home_penalty": null, "away_penalty": null,
        "clock": "0", "updated": 1, "status": "Scheduled",
        "status_type": "scheduled", "query": null, "sport": "soccer"
      }]
    }
    """

    @Test
    func test_decodesLiveAndNextSections() throws {
        let response = try decode(json)

        #expect(response.previous == nil)
        #expect(response.current?.count == 1)
        #expect(response.next?.count == 1)

        let live = try #require(response.current?.first)
        #expect(live.homeTeam?.key == "ENG")
        #expect(live.awayTeam?.key == "USA")
        #expect(live.homeScore == 1)
        #expect(live.awayScore == 0)
        #expect(live.clock == "67")
        #expect(live.statusType == "live")
        #expect(live.homeTeam?.iconUrl == "https://example.com/eng.png")
    }

    @Test
    func test_decodesScheduledMatchWithNullScores() throws {
        let response = try decode(json)
        let scheduled = try #require(response.next?.first)

        #expect(scheduled.homeScore == nil)
        #expect(scheduled.awayScore == nil)
        #expect(scheduled.homePenalty == nil)
        #expect(scheduled.awayPenalty == nil)
        #expect(scheduled.statusType == "scheduled")
        #expect(scheduled.awayTeam?.iconUrl == nil)
    }

    @Test
    func test_decodesPreviousSection_withPenaltyShootout() throws {
        let json = """
        {
          "previous": [{
            "date": "2026-04-29T18:00:00+00:00",
            "global_event_id": 999,
            "home_team": {
              "key": "GER", "name": "Germany",
              "icon_url": null, "group": "Group A", "eliminated": false
            },
            "away_team": {
              "key": "FRA", "name": "France",
              "icon_url": null, "group": "Group A", "eliminated": false
            },
            "period": "FT(P)",
            "home_score": 1, "away_score": 1,
            "home_extra": 1, "away_extra": 1,
            "home_penalty": 5, "away_penalty": 4,
            "clock": "120", "status_type": "past"
          }]
        }
        """
        let response = try decode(json)
        let past = try #require(response.previous?.first)

        #expect(response.previous?.count == 1)
        #expect(response.current == nil)
        #expect(response.next == nil)
        #expect(past.homeExtra == 1)
        #expect(past.awayExtra == 1)
        #expect(past.homePenalty == 5)
        #expect(past.awayPenalty == 4)
        #expect(past.period == "FT(P)")
        #expect(past.statusType == "past")
        #expect(past.homeTeam?.group == "Group A")
        #expect(past.awayTeam?.eliminated == false)
    }

    @Test
    func test_decodesStageValues_intoTypedEnumCases() throws {
        let mappings: [(String, WorldCupMatchesResponse.Match.Stage)] = [
            ("Group Stage", .groupStage),
            ("Round of 32", .roundOf32),
            ("Round of 16", .roundOf16),
            ("Quarter-finals", .quarterFinals),
            ("Semi-finals", .semiFinals),
            ("3rd Place", .thirdPlace),
            ("Final", .final)
        ]
        for (raw, expected) in mappings {
            let response = try decode(stageJSON(raw: "\"\(raw)\""))
            #expect(response.current?.first?.stage == expected)
        }
    }

    @Test
    func test_decodesUnknownStage_intoUnknownCase_preservingRawValue() throws {
        let response = try decode(stageJSON(raw: "\"Galactic Quarterfinals\""))
        #expect(response.current?.first?.stage == .unknown("Galactic Quarterfinals"))
    }

    @Test
    func test_decodesNullStage_asNil() throws {
        let response = try decode(stageJSON(raw: "null"))
        #expect(response.current?.first?.stage == nil)
    }

    private func stageJSON(raw: String) -> String {
        """
        {
          "current": [{
            "date": "2026-04-30T14:00:00+00:00",
            "global_event_id": 1,
            "home_team": { "key": "ENG", "name": "England", "icon_url": null,
                           "group": "Group C", "eliminated": false },
            "away_team": { "key": "USA", "name": "USA", "icon_url": null,
                           "group": "Group C", "eliminated": false },
            "stage": \(raw)
          }]
        }
        """
    }

    @Test
    func test_decodesEmptyTopLevelObject() throws {
        let response = try decode("{}")
        #expect(response.previous == nil)
        #expect(response.current == nil)
        #expect(response.next == nil)
    }

    @Test
    func test_decodesEmptyArrays() throws {
        let response = try decode(#"{ "previous": [], "current": [], "next": [] }"#)
        #expect(response.previous?.isEmpty == true)
        #expect(response.current?.isEmpty == true)
        #expect(response.next?.isEmpty == true)
    }

    @Test
    func test_decodesIgnoresUnknownTopLevelKeys() throws {
        let response = try decode(#"{ "current": [], "unknown_field": "ignored", "extra": 42 }"#)
        #expect(response.current?.isEmpty == true)
    }

    @Test
    func test_responseEquality_sameContent() {
        let responseA = WorldCupMatchesResponse(previous: nil, current: nil, next: nil)
        let responseB = WorldCupMatchesResponse(previous: nil, current: nil, next: nil)
        #expect(responseA == responseB)
    }

    @Test
    func test_responseEquality_differentBuckets() {
        let responseA = WorldCupMatchesResponse(previous: nil, current: nil, next: nil)
        let responseB = WorldCupMatchesResponse(previous: nil, current: [], next: nil)
        #expect(responseA != responseB)
    }

    @Test
    func test_filteredToTeam_keepsOnlyMatchesInvolvingTeam_inEachBucket() {
        let team = WorldCupMatchesResponse.Team(
            key: "BRA", name: "Brazil", iconUrl: nil, group: "Group A", eliminated: false
        )
        let other = WorldCupMatchesResponse.Team(
            key: "ENG", name: "England", iconUrl: nil, group: "Group C", eliminated: false
        )
        let third = WorldCupMatchesResponse.Team(
            key: "ARG", name: "Argentina", iconUrl: nil, group: "Group A", eliminated: false
        )

        func match(_ id: Int, home: WorldCupMatchesResponse.Team, away: WorldCupMatchesResponse.Team)
        -> WorldCupMatchesResponse.Match {
            WorldCupMatchesResponse.Match(
                date: "2026-06-12T18:00:00+00:00",
                globalEventId: id,
                homeTeam: home,
                awayTeam: away
            )
        }

        let response = WorldCupMatchesResponse(
            previous: [match(1, home: team, away: other), match(2, home: other, away: third)],
            current: [match(3, home: third, away: team)],
            next: [match(4, home: other, away: third)]
        )

        let filtered = response.filtered(toTeam: "BRA")

        #expect(filtered.previous?.map(\.globalEventId) == [1])
        #expect(filtered.current?.map(\.globalEventId) == [3])
        #expect(filtered.next?.isEmpty == true)
    }

    @Test
    func test_filteredToTeam_preservesNowField() {
        let response = WorldCupMatchesResponse(
            now: "2026-06-12T12:00:00Z",
            previous: nil,
            current: nil,
            next: nil
        )
        #expect(response.filtered(toTeam: "BRA").now == "2026-06-12T12:00:00Z")
    }

    @Test
    func test_filteredToTeam_nilBuckets_stayNil() {
        let response = WorldCupMatchesResponse(previous: nil, current: nil, next: nil)
        let filtered = response.filtered(toTeam: "BRA")
        #expect(filtered.previous == nil)
        #expect(filtered.current == nil)
        #expect(filtered.next == nil)
    }

    @Test
    func test_matchEquality() {
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
            awayTeam: team,
            period: nil,
            homeScore: nil,
            awayScore: nil,
            homeExtra: nil,
            awayExtra: nil,
            homePenalty: nil,
            awayPenalty: nil,
            clock: nil,
            statusType: nil
        )
        let matchB = matchA
        let matchC = WorldCupMatchesResponse.Match(
            date: "2026-05-11T14:00:00+00:00",
            globalEventId: 2,
            homeTeam: team,
            awayTeam: team,
            period: nil,
            homeScore: nil,
            awayScore: nil,
            homeExtra: nil,
            awayExtra: nil,
            homePenalty: nil,
            awayPenalty: nil,
            clock: nil,
            statusType: nil
        )
        #expect(matchA == matchB)
        #expect(matchA != matchC)
    }

    // MARK: - Match.winnerTeam

    @Test
    func test_match_winnerTeam_returnsHomeTeam_whenHomeScoreHigher() {
        let match = makeMatch(homeKey: "BRA", awayKey: "ARG", homeScore: 2, awayScore: 1)
        #expect(match.winnerTeam?.key == "BRA")
    }

    @Test
    func test_match_winnerTeam_returnsAwayTeam_whenAwayScoreHigher() {
        let match = makeMatch(homeKey: "BRA", awayKey: "ARG", homeScore: 0, awayScore: 3)
        #expect(match.winnerTeam?.key == "ARG")
    }

    @Test
    func test_match_winnerTeam_returnsNil_whenScoresAreEqual_andNoPenalties() {
        let match = makeMatch(homeKey: "BRA", awayKey: "ARG", homeScore: 1, awayScore: 1)
        #expect(match.winnerTeam == nil)
    }

    @Test
    func test_match_winnerTeam_factorsInExtraTimeGoals() {
        // 1-1 in regulation, but home scored an extra-time goal — home wins.
        let match = makeMatch(
            homeKey: "BRA",
            awayKey: "ARG",
            homeScore: 1,
            awayScore: 1,
            homeExtra: 1,
            awayExtra: 0
        )
        #expect(match.winnerTeam?.key == "BRA")
    }

    @Test
    func test_match_winnerTeam_penaltyShootoutDecidesWinner_overEqualRegulationScore() {
        let match = makeMatch(
            homeKey: "GER",
            awayKey: "FRA",
            homeScore: 1,
            awayScore: 1,
            homePenalty: 5,
            awayPenalty: 4
        )
        #expect(match.winnerTeam?.key == "GER")
    }

    @Test
    func test_match_winnerTeam_penaltyTakesPrecedenceOverRegulation() {
        // Regulation 2-1 home, but the API somehow also includes penalties —
        // shootout is authoritative.
        let match = makeMatch(
            homeKey: "GER",
            awayKey: "FRA",
            homeScore: 2,
            awayScore: 1,
            homePenalty: 3,
            awayPenalty: 5
        )
        #expect(match.winnerTeam?.key == "FRA")
    }

    @Test
    func test_match_winnerTeam_returnsNil_whenPenaltiesAreTied() {
        let match = makeMatch(
            homeKey: "GER",
            awayKey: "FRA",
            homeScore: 1,
            awayScore: 1,
            homePenalty: 4,
            awayPenalty: 4
        )
        #expect(match.winnerTeam == nil)
    }

    @Test
    func test_match_winnerTeam_returnsNil_whenScoresAreMissing() {
        let match = makeMatch(homeKey: "BRA", awayKey: "ARG", homeScore: nil, awayScore: nil)
        #expect(match.winnerTeam == nil)
    }

    @Test
    func test_match_winnerTeam_returnsNil_whenHomeTeamIsMissing() {
        let away = WorldCupMatchesResponse.Team(
            key: "ARG", name: "Argentina", iconUrl: nil, group: nil, eliminated: false
        )
        let match = WorldCupMatchesResponse.Match(
            date: "2026-07-19T18:00:00+00:00",
            globalEventId: 1,
            homeTeam: nil,
            awayTeam: away,
            homeScore: 0,
            awayScore: 2
        )
        #expect(match.winnerTeam == nil)
    }

    private func makeMatch(homeKey: String,
                           awayKey: String,
                           homeScore: Int? = nil,
                           awayScore: Int? = nil,
                           homeExtra: Int? = nil,
                           awayExtra: Int? = nil,
                           homePenalty: Int? = nil,
                           awayPenalty: Int? = nil) -> WorldCupMatchesResponse.Match {
        WorldCupMatchesResponse.Match(
            date: "2026-07-19T18:00:00+00:00",
            globalEventId: 1,
            homeTeam: WorldCupMatchesResponse.Team(
                key: homeKey, name: homeKey, iconUrl: nil, group: nil, eliminated: false
            ),
            awayTeam: WorldCupMatchesResponse.Team(
                key: awayKey, name: awayKey, iconUrl: nil, group: nil, eliminated: false
            ),
            homeScore: homeScore,
            awayScore: awayScore,
            homeExtra: homeExtra,
            awayExtra: awayExtra,
            homePenalty: homePenalty,
            awayPenalty: awayPenalty
        )
    }

    private func decode(_ json: String) throws -> WorldCupMatchesResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WorldCupMatchesResponse.self, from: Data(json.utf8))
    }
}
