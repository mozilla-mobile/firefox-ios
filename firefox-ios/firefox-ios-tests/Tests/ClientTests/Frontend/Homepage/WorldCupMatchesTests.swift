// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupMatches view-model")
struct WorldCupMatchesTests {
    @Test
    func test_init_withLiveMatches_marksLiveAndUsesCurrentAsFeatured() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [
                makeMatch(home: "ENG", away: "USA", homeScore: 1, awayScore: 0, clock: "67"),
                makeMatch(home: "BRA", away: "GER", homeScore: 2, awayScore: 2, clock: "90+15")
            ],
            next: [
                makeMatch(home: "ARG", away: "ENG"),
                makeMatch(home: "FRA", away: "USA"),
                makeMatch(home: "BRA", away: "GER")
            ]
        )

        let model = WorldCupMatches(response: response)

        #expect(model.isLive)
        #expect(model.featuredMatch.map(\.homeCode) == ["ENG", "BRA"])
        #expect(model.upcomingMatches.map(\.homeCode) == ["ARG", "FRA"])
    }

    @Test
    func test_init_noLiveMatches_picksFirstScheduledAsFeaturedAndNextTwoAsUpcoming() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [],
            next: [
                makeMatch(home: "ARG", away: "ENG"),
                makeMatch(home: "FRA", away: "USA"),
                makeMatch(home: "BRA", away: "GER"),
                makeMatch(home: "POR", away: "ESP")
            ]
        )

        let model = WorldCupMatches(response: response)

        #expect(!model.isLive)
        #expect(model.featuredMatch.map(\.homeCode) == ["ARG"])
        #expect(model.upcomingMatches.map(\.homeCode) == ["FRA", "BRA"])
    }

    @Test
    func test_init_emptyResponse_returnsEmptyArrays() {
        let response = WorldCupMatchesResponse(previous: nil, current: nil, next: nil)
        let model = WorldCupMatches(response: response)

        #expect(!model.isLive)
        #expect(model.featuredMatch.isEmpty)
        #expect(model.upcomingMatches.isEmpty)
    }

    @Test
    func test_match_score_regulationOnly() {
        let match = WorldCupMatch(
            makeMatch(home: "ENG", away: "USA", homeScore: 1, awayScore: 0, clock: "67")
        )
        #expect(match.score?.score == "1 – 0")
        #expect(match.score?.clock == "67'")
    }

    @Test
    func test_match_score_withPenaltyShootout() {
        let match = WorldCupMatch(makeMatch(
            home: "GER",
            away: "FRA",
            homeScore: 1,
            awayScore: 1,
            homePenalty: 5,
            awayPenalty: 4,
            clock: "120"
        ))
        #expect(match.score?.score == "1 (5) – 1 (4)")
        #expect(match.score?.clock == "120'")
    }

    @Test
    func test_match_score_isNilForScheduledMatches() {
        let match = WorldCupMatch(
            makeMatch(home: "ARG", away: "ENG", homeScore: nil, awayScore: nil)
        )
        #expect(match.score == nil)
    }

    @Test
    func test_phaseTitle_groupStage_whenTeamsHaveGroup() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [makeMatch(home: "ENG", away: "USA", group: "Group C")],
            next: nil
        )

        #expect(WorldCupMatches.phaseTitle(from: response)
                == String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel)
    }

    @Test
    func test_phaseTitle_groupStage_whenGroupOnlyInUpcoming() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [],
            next: [makeMatch(home: "ARG", away: "FRA", group: "Group A")]
        )

        #expect(WorldCupMatches.phaseTitle(from: response)
                == String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel)
    }

    @Test
    func test_phaseTitle_upcoming_whenNoTeamsHaveGroup() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [makeMatch(home: "ENG", away: "USA", group: nil)],
            next: [makeMatch(home: "BRA", away: "GER", group: nil)]
        )

        #expect(WorldCupMatches.phaseTitle(from: response)
                == String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel)
    }

    @Test
    func test_phaseTitle_upcoming_whenResponseIsEmpty() {
        let response = WorldCupMatchesResponse(previous: nil, current: nil, next: nil)

        #expect(WorldCupMatches.phaseTitle(from: response)
                == String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel)
    }

    @Test
    func test_phaseTitle_ignoresPreviousMatches() {
        let response = WorldCupMatchesResponse(
            previous: [makeMatch(home: "BRA", away: "ARG", group: "Group A")],
            current: nil,
            next: nil
        )

        #expect(WorldCupMatches.phaseTitle(from: response)
                == String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel)
    }

    private func makeMatch(home: String,
                           away: String,
                           homeScore: Int? = nil,
                           awayScore: Int? = nil,
                           homeExtra: Int? = nil,
                           awayExtra: Int? = nil,
                           homePenalty: Int? = nil,
                           awayPenalty: Int? = nil,
                           clock: String? = nil,
                           group: String? = nil) -> WorldCupMatchesResponse.Match {
        let homeTeam = WorldCupMatchesResponse.Team(
            key: home,
            name: home,
            iconUrl: nil,
            group: group,
            eliminated: false
        )
        let awayTeam = WorldCupMatchesResponse.Team(
            key: away,
            name: away,
            iconUrl: nil,
            group: group,
            eliminated: false
        )
        return WorldCupMatchesResponse.Match(
            date: "2026-05-01T15:00:00+00:00",
            globalEventId: 0,
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            period: nil,
            homeScore: homeScore,
            awayScore: awayScore,
            homeExtra: homeExtra,
            awayExtra: awayExtra,
            homePenalty: homePenalty,
            awayPenalty: awayPenalty,
            clock: clock,
            statusType: nil
        )
    }
}
