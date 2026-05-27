// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupMatches view-model")
struct WorldCupMatchesTests {
    @Test
    func test_init_matchInsideFeaturedWindow_isHero_othersGoToRow() {
        // Now = Jun 12 20:00. BRA-GER kicked off at 18:30 (90 min ago, inside
        // the 2h featured window) and is the hero. Everything else — older
        // past + future — drops to the compact row, chronologically, capped
        // at two.
        let response = WorldCupMatchesResponse(
            previous: [
                makeMatch(id: 1,
                          home: "ENG",
                          away: "USA",
                          date: "2026-06-11T18:00:00+00:00",
                          homeScore: 1,
                          awayScore: 0)
            ],
            current: [
                makeMatch(id: 2,
                          home: "BRA",
                          away: "GER",
                          date: "2026-06-12T18:30:00+00:00",
                          homeScore: 1,
                          awayScore: 1,
                          clock: "90")
            ],
            next: [
                makeMatch(id: 3, home: "ARG", away: "ENG", date: "2026-06-13T18:00:00+00:00"),
                makeMatch(id: 4, home: "FRA", away: "USA", date: "2026-06-14T18:00:00+00:00")
            ]
        )

        let model = WorldCupMatches(
            response: response,
            liveIDs: [2],
            now: parse("2026-06-12T20:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(model.isLive)
        #expect(model.featuredMatch.map(\.homeCode) == ["BRA"])
        #expect(model.upcomingMatches.map(\.homeCode) == ["ENG", "ARG"])
    }

    @Test
    func test_init_pastFeaturedWindow_promotesNextUpcomingToHero() {
        // Mock scenario: MEX-RSA kicked off at 19:00 and finished 4-0. Now =
        // 22:00, three hours past kickoff — outside the 2h featured window.
        // The user's expectation is that the just-played match drops to the
        // row and the next upcoming (MEX-KOR) takes the hero slot.
        let response = WorldCupMatchesResponse(
            previous: [
                makeMatch(id: 1,
                          home: "MEX",
                          away: "RSA",
                          date: "2026-06-11T19:00:00+00:00",
                          homeScore: 4,
                          awayScore: 0)
            ],
            current: nil,
            next: [
                makeMatch(id: 2, home: "MEX", away: "KOR", date: "2026-06-19T03:00:00+00:00"),
                makeMatch(id: 3, home: "CZE", away: "MEX", date: "2026-06-25T03:00:00+00:00")
            ]
        )

        let model = WorldCupMatches(
            response: response,
            now: parse("2026-06-11T22:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(model.featuredMatch.map(\.homeCode) == ["MEX"])
        #expect(model.featuredMatch.first?.awayCode == "KOR")
        // Row holds the past result first (older) and the remaining future
        // match second, both capped at two.
        #expect(model.upcomingMatches.map(\.homeCode) == ["MEX", "CZE"])
        #expect(model.upcomingMatches.first?.awayCode == "RSA")
        #expect(model.upcomingMatches.last?.awayCode == "MEX")
    }

    @Test
    func test_init_whenAllMatchesArePast_promotesMostRecentToHero() {
        let response = WorldCupMatchesResponse(
            previous: [
                makeMatch(id: 1,
                          home: "ENG",
                          away: "USA",
                          date: "2026-06-11T18:00:00+00:00",
                          homeScore: 1,
                          awayScore: 0),
                makeMatch(id: 2,
                          home: "ARG",
                          away: "BRA",
                          date: "2026-06-14T18:00:00+00:00",
                          homeScore: 2,
                          awayScore: 1)
            ],
            current: nil,
            next: nil
        )

        // Two days past the latest match — well outside the featured window.
        let model = WorldCupMatches(
            response: response,
            now: parse("2026-06-16T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(model.featuredMatch.map(\.homeCode) == ["ARG"])
        #expect(model.upcomingMatches.map(\.homeCode) == ["ENG"])
    }

    @Test
    func test_init_withoutLiveIDs_isNotLiveEvenIfTodayHasMatches() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [makeMatch(id: 1,
                                home: "ENG",
                                away: "USA",
                                date: "2026-06-12T18:00:00+00:00",
                                homeScore: 1,
                                awayScore: 0)],
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

    // MARK: - perStage (single-team multi-card)

    @Test
    func test_perStage_groupOnly_yieldsSingleGroupCardWithM2Layout() {
        // M2-preserved: when the team only has group-stage matches in the
        // response, perStage emits one card with the M2 featured/upcoming
        // layout (next/live match featured, others in the row).
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "CAN", away: "BIH", date: "2026-06-12T19:00:00+00:00", stage: .groupStage),
                makeMatch(id: 2, home: "CAN", away: "QAT", date: "2026-06-18T22:00:00+00:00", stage: .groupStage)
            ]
        )

        let result = WorldCupMatches.perStage(
            response: response,
            now: parse("2026-06-10T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards.count == 1)
        let card = result.cards[0]
        #expect(!card.featuredMatch.isEmpty)
        #expect(card.featuredMatch.count + card.upcomingMatches.count == 2)
        #expect(result.defaultIndex == 0)
    }

    @Test
    func test_perStage_groupPlusKnockout_yieldsTwoCards_landingOnKnockout() {
        // M3 spec: group history on one card, R32 fixture on its own card.
        // Default lands on the latest stage (R32).
        let response = WorldCupMatchesResponse(
            previous: [
                makeMatch(id: 1, home: "CAN", away: "BIH", date: "2026-06-12T19:00:00+00:00", stage: .groupStage),
                makeMatch(id: 2, home: "CAN", away: "QAT", date: "2026-06-18T22:00:00+00:00", stage: .groupStage),
                makeMatch(id: 3, home: "CHE", away: "CAN", date: "2026-06-24T19:00:00+00:00", stage: .groupStage)
            ],
            current: nil,
            next: [
                makeMatch(id: 4, home: "MEX", away: "CAN", date: "2026-06-28T13:00:00+00:00", stage: .roundOf32)
            ]
        )

        let result = WorldCupMatches.perStage(
            response: response,
            now: parse("2026-06-26T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards.count == 2)
        #expect(result.cards[1].phaseTitle == String.WorldCup.HomepageWidget.RoundPhase.Round32Label)
        #expect(result.cards[1].featuredMatch.count == 1)
        #expect(result.cards[1].upcomingMatches.isEmpty)
        #expect(result.defaultIndex == 1)
    }

    @Test
    func test_perStage_threeStages_landsOnLatest() {
        // Team has progressed through group + R32 and now has an R16
        // fixture. Three cards; default lands on R16.
        let response = WorldCupMatchesResponse(
            previous: [
                makeMatch(id: 1, home: "CAN", away: "BIH", date: "2026-06-12T19:00:00+00:00", stage: .groupStage),
                makeMatch(id: 2, home: "CAN", away: "MEX", date: "2026-06-28T13:00:00+00:00", stage: .roundOf32)
            ],
            current: nil,
            next: [
                makeMatch(id: 3, home: "CAN", away: "BRA", date: "2026-07-04T18:00:00+00:00", stage: .roundOf16)
            ]
        )

        let result = WorldCupMatches.perStage(
            response: response,
            now: parse("2026-06-30T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards.count == 3)
        #expect(result.cards[1].phaseTitle == String.WorldCup.HomepageWidget.RoundPhase.Round32Label)
        #expect(result.cards[2].phaseTitle == String.WorldCup.HomepageWidget.RoundPhase.Round16Label)
        #expect(result.defaultIndex == 2)
    }

    @Test
    func test_perStage_emptyResponse_returnsSingleEmptyPlaceholderCard() {
        // Pre-tournament: response window has nothing for the team yet.
        // Still surface a placeholder card so the homepage section renders.
        let response = WorldCupMatchesResponse(previous: nil, current: nil, next: nil)

        let result = WorldCupMatches.perStage(response: response, calendar: utcCalendar())

        #expect(result.cards.count == 1)
        #expect(result.cards[0].featuredMatch.isEmpty)
        #expect(result.cards[0].upcomingMatches.isEmpty)
        #expect(result.defaultIndex == 0)
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
    func test_flattened_defaultIndex_isAlwaysZero() {
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

        #expect(result.defaultIndex == 0)
    }

    @Test
    func test_flattened_promotesLiveMatchToFeatured_andRestStaysInUpcoming() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [
                makeMatch(id: 10, home: "ARG", away: "BRA", date: "2026-06-12T18:00:00+00:00"),
                makeMatch(id: 11, home: "ENG", away: "USA", date: "2026-06-12T21:00:00+00:00")
            ],
            next: nil
        )

        let result = WorldCupMatches.flattened(
            response: response,
            liveIDs: [11],
            now: parse("2026-06-12T20:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards[0].featuredMatch.map(\.homeCode) == ["ENG"])
        #expect(result.cards[0].upcomingMatches.map(\.homeCode) == ["ARG"])
        #expect(result.defaultIndex == 0)
    }

    @Test
    func test_flattened_promotesAllLiveMatchesToFeatured() {
        // Two simultaneous lives on the same day, both get the hero spot.
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: [
                makeMatch(id: 10, home: "ARG", away: "BRA", date: "2026-06-12T13:00:00+00:00"),
                makeMatch(id: 11, home: "ENG", away: "USA", date: "2026-06-12T19:00:00+00:00")
            ],
            next: nil
        )

        let result = WorldCupMatches.flattened(
            response: response,
            liveIDs: [10, 11],
            now: parse("2026-06-12T20:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards[0].featuredMatch.map(\.homeCode) == ["ARG", "ENG"])
        #expect(result.cards[0].upcomingMatches.isEmpty)
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

    @Test
    func test_flattened_includesKnockoutMatches_notJustGroupStage() {
        // Pre-M3 the per-day view dropped anything non-group-stage; M3 needs
        // knockouts in the same flattened cards so the elimination fallback
        // works end-to-end.
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-30T18:00:00+00:00", stage: .roundOf16),
                makeMatch(id: 2, home: "ENG", away: "USA", date: "2026-07-04T18:00:00+00:00", stage: .quarterFinals)
            ]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-06-29T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards.count == 2)
        #expect(result.cards[0].upcomingMatches.map(\.homeCode) == ["ARG"])
        #expect(result.cards[1].upcomingMatches.map(\.homeCode) == ["ENG"])
    }

    @Test
    func test_flattened_titleReflectsStageOfThatDaysMatches() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-06-15T18:00:00+00:00", stage: .groupStage),
                makeMatch(id: 2, home: "ENG", away: "USA", date: "2026-06-30T18:00:00+00:00", stage: .roundOf16),
                makeMatch(id: 3, home: "FRA", away: "GER", date: "2026-07-04T18:00:00+00:00", stage: .quarterFinals),
                makeMatch(id: 4, home: "ESP", away: "ITA", date: "2026-07-15T18:00:00+00:00", stage: .final)
            ]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-06-10T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards.map(\.phaseTitle) == [
            String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel,
            String.WorldCup.HomepageWidget.RoundPhase.Round16Label,
            String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel,
            String.WorldCup.HomepageWidget.RoundPhase.FinalLabel
        ])
    }

    @Test
    func test_flattened_knockoutStage_collapsesAllMatchesIntoOneCard_acrossDays() {
        // QF runs across two days in the real bracket. The flattened view
        // should collapse all 4 QF matches onto a single "Quarter-Finals"
        // card instead of splitting by day, so the user doesn't see "2 of
        // 4 quarter-finals" on each of two cards.
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "FRA", away: "UZB", date: "2026-07-09T13:00:00+00:00", stage: .quarterFinals),
                makeMatch(id: 2, home: "GER", away: "IRQ", date: "2026-07-09T16:00:00+00:00", stage: .quarterFinals),
                makeMatch(id: 3, home: "BRA", away: "ENG", date: "2026-07-10T13:00:00+00:00", stage: .quarterFinals),
                makeMatch(id: 4, home: "ARG", away: "ESP", date: "2026-07-10T16:00:00+00:00", stage: .quarterFinals)
            ]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-07-08T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards.count == 1)
        #expect(result.cards[0].phaseTitle == String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel)
        // All four matches live on the one card. Date label is nil
        // because the matches span two days.
        #expect(result.cards[0].upcomingMatches.count == 4)
        #expect(result.cards[0].dateLabel == nil)
    }

    @Test
    func test_flattened_separatesKnockoutStagesIntoOneCardEach() {
        // Multi-stage scenario: R16 + QF + SF + Final all in the response.
        // Each stage becomes its own card, ordered by tournament progression.
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1, home: "ARG", away: "BRA", date: "2026-07-04T18:00:00+00:00", stage: .roundOf16),
                makeMatch(id: 2, home: "ENG", away: "USA", date: "2026-07-05T18:00:00+00:00", stage: .roundOf16),
                makeMatch(id: 3, home: "FRA", away: "GER", date: "2026-07-09T18:00:00+00:00", stage: .quarterFinals),
                makeMatch(id: 4, home: "ESP", away: "ITA", date: "2026-07-14T18:00:00+00:00", stage: .semiFinals),
                makeMatch(id: 5, home: "NLD", away: "JPN", date: "2026-07-19T18:00:00+00:00", stage: .final)
            ]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-07-03T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards.count == 4)
        #expect(result.cards.map(\.phaseTitle) == [
            String.WorldCup.HomepageWidget.RoundPhase.Round16Label,
            String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel,
            String.WorldCup.HomepageWidget.RoundPhase.SemiFinalsLabel,
            String.WorldCup.HomepageWidget.RoundPhase.FinalLabel
        ])
        #expect(result.cards[0].upcomingMatches.count == 2)
    }

    @Test
    func test_flattened_unknownStage_titleFallsBackToUpcoming() {
        let response = WorldCupMatchesResponse(
            previous: nil,
            current: nil,
            next: [
                makeMatch(id: 1,
                          home: "ARG",
                          away: "BRA",
                          date: "2026-06-30T18:00:00+00:00",
                          stage: .unknown("Galactic Quarterfinals"))
            ]
        )

        let result = WorldCupMatches.flattened(
            response: response,
            now: parse("2026-06-29T12:00:00+00:00"),
            calendar: utcCalendar()
        )

        #expect(result.cards[0].phaseTitle == String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel)
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

    // MARK: - missing team fallbacks

    @Test
    func test_match_init_nilHomeTeam_fallsBackToPlaceholderCodeAndFlag() {
        let match = WorldCupMatch(
            makeMatch(id: 0, home: nil, away: "USA")
        )

        #expect(match.homeCode == WorldCupMatch.missingTeamPlaceholder)
        #expect(match.homeFlagAssetName == WorldCupMatch.missingTeamFlagAssetPlaceholder)
        #expect(match.awayCode == "USA")
        #expect(match.awayFlagAssetName == "USA")
    }

    @Test
    func test_match_init_nilAwayTeam_fallsBackToPlaceholderCodeAndFlag() {
        let match = WorldCupMatch(
            makeMatch(id: 0, home: "ENG", away: nil)
        )

        #expect(match.awayCode == WorldCupMatch.missingTeamPlaceholder)
        #expect(match.awayFlagAssetName == WorldCupMatch.missingTeamFlagAssetPlaceholder)
        #expect(match.homeCode == "ENG")
        #expect(match.homeFlagAssetName == "ENG")
    }

    @Test
    func test_match_init_bothTeamsNil_fallsBackToPlaceholdersForBoth() {
        let match = WorldCupMatch(
            makeMatch(id: 0, home: nil, away: nil)
        )

        #expect(match.homeCode == WorldCupMatch.missingTeamPlaceholder)
        #expect(match.awayCode == WorldCupMatch.missingTeamPlaceholder)
        #expect(match.homeFlagAssetName == WorldCupMatch.missingTeamFlagAssetPlaceholder)
        #expect(match.awayFlagAssetName == WorldCupMatch.missingTeamFlagAssetPlaceholder)
    }

    // MARK: - phaseTitle

    @Test
    func test_phaseTitle_groupStage_usesGroupLetter() {
        let match = makeMatch(id: 0, home: "ENG", away: "USA", group: "Group C", stage: .groupStage)

        #expect(WorldCupMatches.phaseTitle(from: match)
                == String.WorldCup.HomepageWidget.GroupPhase.GroupC)
    }

    @Test
    func test_phaseTitle_groupStage_fallsBackToGenericLabel_whenGroupMissing() {
        let match = makeMatch(id: 0, home: "ENG", away: "USA", group: nil, stage: .groupStage)

        #expect(WorldCupMatches.phaseTitle(from: match)
                == String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel)
    }

    @Test
    func test_phaseTitle_knockoutStages_mapToLocalizedLabels() {
        let mappings: [(WorldCupMatchesResponse.Match.Stage, String)] = [
            (.roundOf32, String.WorldCup.HomepageWidget.RoundPhase.Round32Label),
            (.roundOf16, String.WorldCup.HomepageWidget.RoundPhase.Round16Label),
            (.quarterFinals, String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel),
            (.semiFinals, String.WorldCup.HomepageWidget.RoundPhase.SemiFinalsLabel),
            (.thirdPlace, String.WorldCup.HomepageWidget.RoundPhase.ThirdPlaceLabel),
            (.final, String.WorldCup.HomepageWidget.RoundPhase.FinalLabel)
        ]
        for (stage, expected) in mappings {
            let match = makeMatch(id: 0, home: "BRA", away: "ARG", group: nil, stage: stage)
            #expect(WorldCupMatches.phaseTitle(from: match) == expected)
        }
    }

    @Test
    func test_phaseTitle_unknownStage_fallsBackToUpcoming() {
        let match = makeMatch(id: 0,
                              home: "BRA",
                              away: "ARG",
                              group: nil,
                              stage: .unknown("Galactic Quarterfinals"))

        #expect(WorldCupMatches.phaseTitle(from: match)
                == String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel)
    }

    @Test
    func test_phaseTitle_nilMatch_fallsBackToGroupStage() {
        #expect(WorldCupMatches.phaseTitle(from: nil)
                == String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel)
    }

    // MARK: - winnerThirdPlaceOrFinal

    @Test
    func test_winnerThirdPlaceOrFinal_returnsNil_forNonFinalPhase() {
        let model = WorldCupMatches(
            phaseTitle: String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel,
            isLive: false,
            featuredMatch: [makeViewMatch(home: "BRA", away: "ARG", winnerKey: "BRA")],
            upcomingMatches: []
        )

        #expect(model.winnerThirdPlaceOrFinal == nil)
    }

    @Test
    func test_winnerThirdPlaceOrFinal_returnsWinWorldCupLabel_forFinalPhase() {
        let model = WorldCupMatches(
            phaseTitle: String.WorldCup.HomepageWidget.RoundPhase.FinalLabel,
            isLive: false,
            featuredMatch: [makeViewMatch(home: "BRA", away: "ARG", winnerKey: "BRA")],
            upcomingMatches: []
        )

        let winner = model.winnerThirdPlaceOrFinal
        #expect(winner?.teamKey == "BRA")
        #expect(winner?.winnerLabel == String.WorldCup.HomepageWidget.RoundPhase.WinWorldCupLabel)
    }

    @Test
    func test_winnerThirdPlaceOrFinal_returnsThirdPlaceLabel_forBronzeFinalPhase() {
        let model = WorldCupMatches(
            phaseTitle: String.WorldCup.HomepageWidget.RoundPhase.BronzeFinalLabel,
            isLive: false,
            featuredMatch: [makeViewMatch(home: "FRA", away: "GER", winnerKey: "FRA")],
            upcomingMatches: []
        )

        let winner = model.winnerThirdPlaceOrFinal
        #expect(winner?.teamKey == "FRA")
        #expect(winner?.winnerLabel == String.WorldCup.HomepageWidget.RoundPhase.ThirdPlaceLabel)
    }

    @Test
    func test_winnerThirdPlaceOrFinal_returnsNil_whenNoMatchHasAWinnerKey() {
        // Final hasn't been played yet — neither match has a winnerKey.
        let model = WorldCupMatches(
            phaseTitle: String.WorldCup.HomepageWidget.RoundPhase.FinalLabel,
            isLive: false,
            featuredMatch: [makeViewMatch(home: "BRA", away: "ARG", winnerKey: nil)],
            upcomingMatches: []
        )

        #expect(model.winnerThirdPlaceOrFinal == nil)
    }

    @Test
    func test_winnerThirdPlaceOrFinal_pullsWinnerFromFeaturedMatchFirst() {
        let model = WorldCupMatches(
            phaseTitle: String.WorldCup.HomepageWidget.RoundPhase.FinalLabel,
            isLive: false,
            featuredMatch: [makeViewMatch(home: "BRA", away: "ARG", winnerKey: "BRA")],
            upcomingMatches: [makeViewMatch(home: "FRA", away: "GER", winnerKey: "FRA")]
        )

        #expect(model.winnerThirdPlaceOrFinal?.teamKey == "BRA")
    }

    @Test
    func test_winnerThirdPlaceOrFinal_fallsBackToUpcomingMatch_whenFeaturedHasNoWinner() {
        let model = WorldCupMatches(
            phaseTitle: String.WorldCup.HomepageWidget.RoundPhase.FinalLabel,
            isLive: false,
            featuredMatch: [makeViewMatch(home: "BRA", away: "ARG", winnerKey: nil)],
            upcomingMatches: [makeViewMatch(home: "FRA", away: "GER", winnerKey: "GER")]
        )

        #expect(model.winnerThirdPlaceOrFinal?.teamKey == "GER")
    }

    @Test
    func test_winnerThirdPlaceOrFinal_returnsNil_forGroupStagePhase() {
        let model = WorldCupMatches(
            phaseTitle: String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel,
            isLive: false,
            featuredMatch: [makeViewMatch(home: "BRA", away: "ARG", winnerKey: "BRA")],
            upcomingMatches: []
        )

        #expect(model.winnerThirdPlaceOrFinal == nil)
    }

    // MARK: - Helpers

    private func makeViewMatch(home: String,
                               away: String,
                               winnerKey: String? = nil) -> WorldCupMatch {
        WorldCupMatch(
            homeFlagAssetName: home,
            homeCode: home,
            awayFlagAssetName: away,
            awayCode: away,
            date: "2026-07-19T18:00:00+00:00",
            score: nil,
            winnerKey: winnerKey
        )
    }


    private func makeMatch(id: Int,
                           home: String?,
                           away: String?,
                           date: String = "2026-05-01T15:00:00+00:00",
                           homeScore: Int? = nil,
                           awayScore: Int? = nil,
                           homeExtra: Int? = nil,
                           awayExtra: Int? = nil,
                           homePenalty: Int? = nil,
                           awayPenalty: Int? = nil,
                           clock: String? = nil,
                           group: String? = nil,
                           stage: WorldCupMatchesResponse.Match.Stage? = .groupStage)
    -> WorldCupMatchesResponse.Match {
        let homeTeam = home.map {
            WorldCupMatchesResponse.Team(
                key: $0,
                name: $0,
                iconUrl: nil,
                group: group,
                eliminated: false
            )
        }
        let awayTeam = away.map {
            WorldCupMatchesResponse.Team(
                key: $0,
                name: $0,
                iconUrl: nil,
                group: group,
                eliminated: false
            )
        }
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
