// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct WorldCupMatches: Equatable, Hashable {
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

    /// Selection rule:
    /// - If `current` (live) matches exist, those are featured (up to 2) and `isLive` is `true`;
    ///   `upcomingMatches` is the first two of `next`.
    /// - Otherwise the first scheduled match becomes featured, `isLive` is `false`, and the
    ///   following two scheduled matches become `upcomingMatches`.
    init(response: WorldCupMatchesResponse,
         localeProvider: LocaleProvider = SystemLocaleProvider()) {
        let live = response.current ?? []
        let scheduled = response.next ?? []

        let featured: [WorldCupMatchesResponse.Match]
        let upcoming: [WorldCupMatchesResponse.Match]

        if live.isEmpty {
            featured = Array(scheduled.prefix(1))
            upcoming = Array(scheduled.dropFirst(1).prefix(2))
            self.isLive = false
        } else {
            featured = Array(live.prefix(2))
            upcoming = Array(scheduled.prefix(2))
            self.isLive = true
        }

        self.phaseTitle = Self.phaseTitle(from: response)
        self.featuredMatch = featured.map { WorldCupMatch($0, localeProvider: localeProvider) }
        self.upcomingMatches = upcoming.map { WorldCupMatch($0, localeProvider: localeProvider) }
    }

    /// Maps the merino response to a localized phase label. Currently the only
    /// reliable signal in the API is `team.group`. If any featured/upcoming
    /// team carries a group assignment we're in group play. For knockout
    /// rounds the merino payload doesn't yet carry a round identifier, so we
    /// fall back to the generic "Upcoming" label until that exists upstream
    /// or we count surviving teams from the response.
    static func phaseTitle(from response: WorldCupMatchesResponse) -> String {
        let activeMatches = (response.current ?? []) + (response.next ?? [])
        let isGroupStage = activeMatches.contains { match in
            match.homeTeam.group != nil || match.awayTeam.group != nil
        }
        return isGroupStage
            ? String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel
            : String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel
    }
}
