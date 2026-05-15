// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct WorldCupMatches: Equatable, Hashable {
    /// Sentinel for the `limit` parameter on `flattened(response:limit:)`; means
    /// "include every match in the response, no truncation".
    static let unlimitedMatches = Int.max

    let phaseTitle: String
    let isLive: Bool
    let featuredMatch: [WorldCupMatch]
    let upcomingMatches: [WorldCupMatch]

    init(phaseTitle: String,
         isLive: Bool,
         featuredMatch: [WorldCupMatch],
         upcomingMatches: [WorldCupMatch]) {
        self.phaseTitle = phaseTitle
        self.isLive = isLive
        self.featuredMatch = featuredMatch
        self.upcomingMatches = upcomingMatches
    }

    /// Single-card view used when a team is selected: the merino response is
    /// already scoped to that team, so we put any past results plus the live
    /// match (if any) into `featuredMatch` (the prominent top section), and
    /// the next two scheduled matches into `upcomingMatches` (the compact
    /// bottom list). If nothing has happened yet, the first scheduled match
    /// is promoted to featured so the card never opens empty.
    init(response: WorldCupMatchesResponse,
         localeProvider: LocaleProvider = SystemLocaleProvider()) {
        let previous = response.previous ?? []
        let live = response.current ?? []
        let scheduled = response.next ?? []

        var featured = previous + live
        var upcoming = scheduled
        if featured.isEmpty, let firstScheduled = upcoming.first {
            featured = [firstScheduled]
            upcoming = Array(upcoming.dropFirst())
        }
        upcoming = Array(upcoming.prefix(2))

        self.phaseTitle = Self.phaseTitle(from: response)
        self.isLive = !live.isEmpty
        self.featuredMatch = featured.map { WorldCupMatch($0, localeProvider: localeProvider) }
        self.upcomingMatches = upcoming.map { WorldCupMatch($0, localeProvider: localeProvider) }
    }

    /// Multi-card view used when no team is selected: every match in the
    /// response becomes its own one-match card (chronological: previous →
    /// current → next), so swiping flips through the tournament one match at
    /// a time. `limit` caps the count (default unlimited).
    static func flattened(
        response: WorldCupMatchesResponse,
        limit: Int = unlimitedMatches,
        localeProvider: LocaleProvider = SystemLocaleProvider()
    ) -> [WorldCupMatches] {
        let previous = response.previous ?? []
        let live = response.current ?? []
        let scheduled = response.next ?? []
        let title = Self.phaseTitle(from: response)
        let ordered = previous + live + scheduled
        return ordered.prefix(limit).map { match in
            WorldCupMatches(
                phaseTitle: title,
                isLive: match.statusType == "live",
                featuredMatch: [WorldCupMatch(match, localeProvider: localeProvider)],
                upcomingMatches: []
            )
        }
    }

    private static let groupTitles: [String: String] = [
        "Group A": String.WorldCup.HomepageWidget.GroupPhase.GroupA,
        "Group B": String.WorldCup.HomepageWidget.GroupPhase.GroupB,
        "Group C": String.WorldCup.HomepageWidget.GroupPhase.GroupC,
        "Group D": String.WorldCup.HomepageWidget.GroupPhase.GroupD,
        "Group E": String.WorldCup.HomepageWidget.GroupPhase.GroupE,
        "Group F": String.WorldCup.HomepageWidget.GroupPhase.GroupF,
        "Group G": String.WorldCup.HomepageWidget.GroupPhase.GroupG,
        "Group H": String.WorldCup.HomepageWidget.GroupPhase.GroupH,
        "Group I": String.WorldCup.HomepageWidget.GroupPhase.GroupI,
        "Group J": String.WorldCup.HomepageWidget.GroupPhase.GroupJ,
        "Group K": String.WorldCup.HomepageWidget.GroupPhase.GroupK,
        "Group L": String.WorldCup.HomepageWidget.GroupPhase.GroupL
    ]

    private static let roundTitles: [String: String] = [
        "Round of 32": String.WorldCup.HomepageWidget.RoundPhase.Round32Label,
        "Round of 16": String.WorldCup.HomepageWidget.RoundPhase.Round16Label,
        "Quarter-finals": String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel,
        "Semi-finals": String.WorldCup.HomepageWidget.RoundPhase.SemiFinalsLabel,
        "Bronze Final": String.WorldCup.HomepageWidget.RoundPhase.BronzeFinalLabel,
        "Third Place": String.WorldCup.HomepageWidget.RoundPhase.ThirdPlaceLabel,
        "Final": String.WorldCup.HomepageWidget.RoundPhase.FinalLabel
    ]

    /// Maps the merino response to a localized phase label. When the first
    /// active match reports `stage == "Group Stage"`, we resolve the specific
    /// group title (e.g. "Group A") via the team's `group` field. For any
    /// other stage we look the stage string up directly in the round
    /// dictionary. Unknown or missing stages fall back to "Upcoming".
    static func phaseTitle(from response: WorldCupMatchesResponse) -> String {
        let activeMatches = (response.current ?? []) + (response.next ?? [])
        guard let match = activeMatches.first else {
            return String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel
        }

        if match.stage == "Group Stage" {
            let group = match.homeTeam.group ?? match.awayTeam.group
            if let group, let title = groupTitles[group] {
                return title
            }
            return String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel
        }

        if let stage = match.stage, let title = roundTitles[stage] {
            return title
        }

        return String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel
    }
}
