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
    /// already scoped to that team, so we surface everything from it on one
    /// card — past + live as `featuredMatch` (the prominent top section),
    /// scheduled as `upcomingMatches` (the compact bottom list). If nothing
    /// has happened yet, the first scheduled match is promoted to featured so
    /// the card never opens empty.
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
        let liveIDs = Set(live.map(\.globalEventId))
        let ordered = previous + live + scheduled
        return ordered.prefix(limit).map { match in
            WorldCupMatches(
                phaseTitle: title,
                isLive: liveIDs.contains(match.globalEventId),
                featuredMatch: [WorldCupMatch(match, localeProvider: localeProvider)],
                upcomingMatches: []
            )
        }
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
