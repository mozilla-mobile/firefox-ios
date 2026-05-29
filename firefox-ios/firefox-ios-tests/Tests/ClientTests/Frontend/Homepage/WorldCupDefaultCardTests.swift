// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

/// Scenario coverage for which card the World Cup swipe view should land on
/// first. The rules under test:
///
/// 1. Before the tournament starts AND no team is selected → the fox/timer
///    card is the default. This is the only time the timer is ever the
///    default.
/// 2. Once the tournament has started OR a team is selected, the default is
///    a match card chosen by the feed: live → next upcoming → latest.
/// 3. Selecting a team that's already eliminated falls back to the no-team
///    flow (the feed clears the selection); the timer rule from (1) still
///    applies based on `hasWorldCupStarted`.
@MainActor
final class WorldCupDefaultCardTests: XCTestCase {
    // MARK: - Before the World Cup starts (no team selected)

    func test_beforeWorldCupStarts_noTeam_noMatches_landsOnTimer() {
        let state = makeState(hasWorldCupStarted: false,
                              selectedCountryId: nil,
                              matches: [])

        XCTAssertEqual(state.defaultCard, .timer)
    }

    func test_beforeWorldCupStarts_noTeam_withMatches_stillLandsOnTimer() {
        // Even when the feed has matches loaded, pre-tournament + no team
        // must show the fox card so the "follow your team" CTA gets a chance.
        let state = makeState(hasWorldCupStarted: false,
                              selectedCountryId: nil,
                              matches: [makeMatchesCard(), makeMatchesCard()],
                              bestMatchIndex: 1)

        XCTAssertEqual(state.defaultCard, .timer)
    }

    // MARK: - Before the World Cup starts (team selected)

    func test_beforeWorldCupStarts_teamSelected_landsOnFirstCard() {
        // Selecting a team removes the timer from the swipe view (see
        // WorldCupCellFactory), but before kickoff we still pin to the first
        // card regardless of what the feed computed for bestMatchIndex — e.g.
        // a stray past warm-up fixture must not push us off card 0.
        let state = makeState(hasWorldCupStarted: false,
                              selectedCountryId: "BRA",
                              matches: [makeMatchesCard(), makeMatchesCard()],
                              bestMatchIndex: 1)

        XCTAssertEqual(state.defaultCard, .match(0))
    }

    // MARK: - After the World Cup starts (no team selected)

    func test_afterWorldCupStarts_noTeam_landsOnLiveCard() {
        // Live always wins. The feed handed us index 2 → that's a live card.
        let state = makeState(hasWorldCupStarted: true,
                              selectedCountryId: nil,
                              matches: [makeMatchesCard(),
                                        makeMatchesCard(),
                                        makeMatchesCard(isLive: true)],
                              bestMatchIndex: 2)

        XCTAssertEqual(state.defaultCard, .match(2))
    }

    func test_afterWorldCupStarts_noTeam_noLive_landsOnNextUpcoming() {
        // No live → feed already picked the first card whose earliest kickoff
        // is in the future. State just trusts and forwards it.
        let state = makeState(hasWorldCupStarted: true,
                              selectedCountryId: nil,
                              matches: [makeMatchesCard(),
                                        makeMatchesCard(),
                                        makeMatchesCard()],
                              bestMatchIndex: 1)

        XCTAssertEqual(state.defaultCard, .match(1))
    }

    func test_afterWorldCupStarts_noTeam_allMatchesInPast_landsOnLatest() {
        // No live, nothing upcoming → tournament is effectively over for now.
        // The feed pins us to the last card so the homepage still shows the
        // most recent result.
        let state = makeState(hasWorldCupStarted: true,
                              selectedCountryId: nil,
                              matches: [makeMatchesCard(),
                                        makeMatchesCard(),
                                        makeMatchesCard()],
                              bestMatchIndex: 2)

        XCTAssertEqual(state.defaultCard, .match(2))
    }

    func test_afterWorldCupStarts_noTeam_noMatches_fallsBackToTimer() {
        // Edge case: the feed has nothing usable (cold start with no API
        // payload yet). Showing the timer is safer than crashing on an
        // out-of-range index — the section either renders the countdown or
        // an error view, both of which are valid first-card states.
        let state = makeState(hasWorldCupStarted: true,
                              selectedCountryId: nil,
                              matches: [])

        XCTAssertEqual(state.defaultCard, .timer)
    }

    // MARK: - After the World Cup starts (team selected)

    func test_afterWorldCupStarts_teamSelected_landsOnBestMatch() {
        // Team selected → no timer in the pages array at all. Whatever the
        // feed says is the team's most-relevant stage.
        let state = makeState(hasWorldCupStarted: true,
                              selectedCountryId: "BRA",
                              matches: [makeMatchesCard(),
                                        makeMatchesCard()],
                              bestMatchIndex: 1)

        XCTAssertEqual(state.defaultCard, .match(1))
    }

    func test_afterWorldCupStarts_teamSelected_liveStageWins() {
        // The team has a live fixture in stage 0; live should pre-empt the
        // "show latest stage" instinct.
        let state = makeState(hasWorldCupStarted: true,
                              selectedCountryId: "BRA",
                              matches: [makeMatchesCard(isLive: true),
                                        makeMatchesCard()],
                              bestMatchIndex: 0)

        XCTAssertEqual(state.defaultCard, .match(0))
    }

    // MARK: - Clamping

    func test_outOfRangeBestMatchIndex_clampsToLastCard() {
        // Defensive: if the feed ever hands us an index past the array (e.g.
        // mid-update race), clamp instead of crashing on the swipe view.
        let state = makeState(hasWorldCupStarted: true,
                              selectedCountryId: "BRA",
                              matches: [makeMatchesCard(), makeMatchesCard()],
                              bestMatchIndex: 99)

        XCTAssertEqual(state.defaultCard, .match(1))
    }

    func test_negativeBestMatchIndex_clampsToZero() {
        let state = makeState(hasWorldCupStarted: true,
                              selectedCountryId: "BRA",
                              matches: [makeMatchesCard(), makeMatchesCard()],
                              bestMatchIndex: -5)

        XCTAssertEqual(state.defaultCard, .match(0))
    }

    // MARK: - Helpers

    private func makeState(
        hasWorldCupStarted: Bool,
        selectedCountryId: String?,
        matches: [WorldCupMatches],
        bestMatchIndex: Int = 0
    ) -> WorldCupSectionState {
        var state = WorldCupSectionState(windowUUID: .XCTestDefaultUUID)
        state.hasWorldCupStarted = hasWorldCupStarted
        state.selectedCountryId = selectedCountryId
        state.matches = matches
        state.bestMatchIndex = bestMatchIndex
        return state
    }

    private func makeMatchesCard(isLive: Bool = false) -> WorldCupMatches {
        return WorldCupMatches(
            phaseTitle: "Group Stage",
            telemetryPhaseValue: "Group Stage",
            isLive: isLive,
            featuredMatch: [],
            upcomingMatches: []
        )
    }
}
