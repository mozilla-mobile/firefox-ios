// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupMatches view-model")
struct WorldCupMatchesTests {
    @Test
    func test_init_marksLive_andPutsPastAndTodayMatchesInFeatured() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [
                makeMatch(id: 1, home: "ENG", away: "USA",
                          date: "2026-06-11T18:00:00+00:00",
                          homeScore: 1, awayScore: 0, clock: "67"),
                makeMatch(id: 2, home: "BRA", away: "GER",
                          date: "2026-06-12T15:00:00+00:00",
                          homeScore: 2, awayScore: 2, clock: "90+15")
            ],
            next: [
                makeMatch(id: 3, home: "ARG", away: "ENG", date: "2026-06-13T18:00:00+00:00"),
                makeMatch(id: 4, home: "FRA", away: "USA", date: "2026-06-14T18:00:00+00:00"),
                makeMatch(id: 5, home: "BRA", away: "GER", date: "2026-06-15T18:00:00+00:00")
            ]
        )

        let model = WorldCupMatches(
            response: response,
            liveIDs: [1],
            now: parse("2026-06-12T20:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(model.isLive)
        #expect(model.featuredMatch.map(\.homeCode) == ["ENG", "BRA"])
        #expect(model.upcomingMatches.map(\.homeCode) == ["ARG", "FRA"])
    }

    @Test
    func test_init_withoutLiveIDs_isNotLiveEvenIfTodayHasMatches() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [makeMatch(id: 1, home: "ENG", away: "USA",
                                date: "2026-06-12T18:00:00+00:00",
                                homeScore: 1, awayScore: 0)],
            next: nil
        )

        let model = WorldCupMatches(
            response: response,
            liveIDs: [],
            now: parse("2026-06-12T20:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(!model.isLive)
    }

    @Test
    func test_init_withLiveIDs_thatDontMatchAnyMatch_isNotLive() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [makeMatch(id: 1, home: "ENG", away: "USA")],
            next: [makeMatch(id: 2, home: "BRA", away: "GER")]
        )

        let model = WorldCupMatches(response: response, liveIDs: [99])

        #expect(!model.isLive)
    }

    @Test
    func test_init_whenAllMatchesAreInTheFuture_promotesFirstToFeatured() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "CAN", away: "BIH", date: "2026-06-12T21:00:00+00:00"),
                makeMatch(id: 2, home: "CAN", away: "QAT", date: "2026-06-19T00:00:00+00:00"),
                makeMatch(id: 3, home: "CHE", away: "CAN", date: "2026-06-24T21:00:00+00:00")
            ]
        )

        let model = WorldCupMatches(
            response: response,
            now: parse("2026-05-18T09:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(!model.isLive)
        #expect(model.featuredMatch.map(\.homeCode) == ["CAN"])
        #expect(model.upcomingMatches.map(\.homeCode) == ["CAN", "CHE"])
    }

    @Test
    func test_init_ignoresServerBucketing_andUsesRealTodayForSplit() {
        // The merino payload buckets matches relative to the query date (the
        // tournament floor, Jun 18). On May 18 the user's real today is well
        // before any match, so everything should bucket as future regardless
        // of which server label it carried.
        let response = WorldCupMatchesResponse(
            previous: [makeMatch(id: 1, home: "CAN", away: "BIH", date: "2026-06-12T21:00:00+00:00")],
            current: [makeMatch(id: 2, home: "CAN", away: "QAT", date: "2026-06-19T00:00:00+00:00")],
            next: [makeMatch(id: 3, home: "CHE", away: "CAN", date: "2026-06-24T21:00:00+00:00")]
        )

        let model = WorldCupMatches(
            response: response,
            now: parse("2026-05-18T09:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(model.featuredMatch.map(\.homeCode) == ["CAN"])
        #expect(model.upcomingMatches.map(\.homeCode) == ["CAN", "CHE"])
    }

    @Test
    func test_init_emptyResponse_returnsEmptyArrays() {
        let response = WorldCupMatchesResponse(previous: nil, current: nil, next: nil)
        let model = WorldCupMatches(response: response)

        #expect(!model.isLive)
        #expect(model.featuredMatch.isEmpty)
        #expect(model.upcomingMatches.isEmpty)
    }

    // MARK: - flattened (grouped-by-day)

    @Test
    func test_flattened_groupsMatchesOnTheSameDayIntoOneCard() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-12T18:00:00+00:00"),
                makeMatch(id: 2, home: "ENG", away: "USA", date: "2026-06-12T21:00:00+00:00"),
                makeMatch(id: 3, home: "FRA", away: "GER", date: "2026-06-13T15:00:00+00:00")
            ]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-06-10T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards.count == 2)
        #expect(result.cards[0].upcomingMatches.map(\.homeCode) == ["ARG", "ENG"])
        #expect(result.cards[1].upcomingMatches.map(\.homeCode) == ["FRA"])
    }

    @Test
    func test_flattened_leavesFeaturedEmpty_soDayMatchesRenderInCompactRows() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-12T18:00:00+00:00")]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-06-10T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards[0].featuredMatch.isEmpty)
    }

    @Test
    func test_flattened_orderCardsChronologically() {
        let response = WorldCupMatchesResponse(
            previous: [makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-10T18:00:00+00:00")],
            current: [makeMatch(id: 2, home: "ENG", away: "USA", date: "2026-06-12T18:00:00+00:00")],
            next: [makeMatch(id: 3, home: "FRA", away: "GER", date: "2026-06-14T18:00:00+00:00")]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-06-10T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards.map { $0.upcomingMatches.first?.homeCode } == ["ARG", "ENG", "FRA"])
    }

    @Test
    func test_flattened_defaultIndex_pointsAtToday() {
        let response = WorldCupMatchesResponse(
            previous: [makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-10T18:00:00+00:00")],
            current: [makeMatch(id: 2, home: "ENG", away: "USA", date: "2026-06-12T18:00:00+00:00")],
            next: [makeMatch(id: 3, home: "FRA", away: "GER", date: "2026-06-14T18:00:00+00:00")]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-06-12T09:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.defaultIndex == 1)
    }

    @Test
    func test_flattened_defaultIndex_pointsAtNextFutureDay_whenTodayHasNoMatches() {
        let response = WorldCupMatchesResponse(
            previous: [makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-10T18:00:00+00:00")],
            current: nil,
            next: [
                makeMatch(id: 2, home: "ENG", away: "USA", date: "2026-06-13T18:00:00+00:00"),
                makeMatch(id: 3, home: "FRA", away: "GER", date: "2026-06-14T18:00:00+00:00")
            ]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-06-11T09:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.defaultIndex == 1)
    }

    @Test
    func test_flattened_defaultIndex_fallsBackToLastCard_whenEverythingIsInThePast() {
        let response = WorldCupMatchesResponse(
            previous: [
                makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-10T18:00:00+00:00"),
                makeMatch(id: 2, home: "ENG", away: "USA", date: "2026-06-11T18:00:00+00:00")
            ],
            current: nil,
            next: nil
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-07-01T09:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.defaultIndex == 1)
    }

    @Test
    func test_flattened_marksCardLive_whenAnyMatchInDayIsInLiveIDs() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [
                makeMatch(id: 10, home: "ARG", away: "BRA", date: "2026-06-12T18:00:00+00:00"),
                makeMatch(id: 11, home: "ENG", away: "USA", date: "2026-06-12T21:00:00+00:00")
            ],
            next: [makeMatch(id: 12, home: "FRA", away: "GER", date: "2026-06-13T15:00:00+00:00")]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            liveIDs: [11],
            now: parse("2026-06-12T20:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards[0].isLive)
        #expect(!result.cards[1].isLive)
    }

    @Test
    func test_flattened_emptyResponse_returnsEmptyCards() {
        let response = WorldCupMatchesResponse(previous: nil, current: nil, next: nil)

        let result = WorldCupMatches.flattened(response: response, calendar: utcCalendar())

        #expect(result.cards.isEmpty)
        #expect(result.defaultIndex == 0)
    }

    // MARK: - score formatting

    @Test
    func test_match_score_regulationOnly() {
        let match = WorldCupMatch(
            makeMatch(id: 0, home: "ENG", away: "USA", homeScore: 1, awayScore: 0, clock: "67")
        )
        #expect(match.score?.score == "1 – 0")
        #expect(match.score?.clock == "67'")
    }

    @Test
    func test_match_score_withPenaltyShootout() {
        let match = WorldCupMatch(makeMatch(
            id: 0,
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
            makeMatch(id: 0, home: "ARG", away: "ENG", homeScore: nil, awayScore: nil)
        )
        #expect(match.score == nil)
    }

    // MARK: - phaseTitle

    @Test
    func test_phaseTitle_groupStage_usesGroupLetter() {
        let match = makeMatch(id: 0, home: "ENG", away: "USA", group: "Group C", stage: "Group Stage")

        #expect(WorldCupMatches.phaseTitle(from: match)
                == String.WorldCup.HomepageWidget.GroupPhase.GroupC)
    }

    @Test
    func test_phaseTitle_groupStage_fallsBackToGenericLabel_whenGroupMissing() {
        let match = makeMatch(id: 0, home: "ENG", away: "USA", group: nil, stage: "Group Stage")

        #expect(WorldCupMatches.phaseTitle(from: match)
                == String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel)
    }

    @Test
    func test_phaseTitle_knockoutStages_mapToLocalizedLabels() {
        let mappings: [(String, String)] = [
            ("Round of 32", String.WorldCup.HomepageWidget.RoundPhase.Round32Label),
            ("Round of 16", String.WorldCup.HomepageWidget.RoundPhase.Round16Label),
            ("Quarterfinals", String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel),
            ("Semifinals", String.WorldCup.HomepageWidget.RoundPhase.SemiFinalsLabel),
            ("Third Place", String.WorldCup.HomepageWidget.RoundPhase.ThirdPlaceLabel),
            ("Final", String.WorldCup.HomepageWidget.RoundPhase.FinalLabel)
        ]
        for (stage, expected) in mappings {
            let match = makeMatch(id: 0, home: "BRA", away: "ARG", group: nil, stage: stage)
            #expect(WorldCupMatches.phaseTitle(from: match) == expected)
        }
    }

    @Test
    func test_phaseTitle_unknownStage_fallsBackToUpcoming() {
        let match = makeMatch(id: 0, home: "BRA", away: "ARG", group: nil, stage: "Galactic Quarterfinals")

        #expect(WorldCupMatches.phaseTitle(from: match)
                == String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel)
    }

    @Test
    func test_phaseTitle_nilMatch_fallsBackToGroupStage() {
        #expect(WorldCupMatches.phaseTitle(from: nil)
                == String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel)
    }

    // MARK: - Helpers

    private func makeMatch(id: Int,
                           home: String,
                           away: String,
                           date: String = "2026-05-01T15:00:00+00:00",
                           homeScore: Int? = nil,
                           awayScore: Int? = nil,
                           homeExtra: Int? = nil,
                           awayExtra: Int? = nil,
                           homePenalty: Int? = nil,
                           awayPenalty: Int? = nil,
                           clock: String? = nil,
                           group: String? = nil,
                           stage: String? = nil) -> WorldCupMatchesResponse.Match {
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
            date: date,
            globalEventId: id,
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
            statusType: nil,
            stage: stage
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private func parse(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: iso)!
    }
}
