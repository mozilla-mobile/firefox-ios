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

    /// How long a match stays in the prominent "hero" slot after kickoff
    /// before falling to the compact row. Covers the ~110-min live window
    /// plus a bit of post-FT result-viewing so a just-finished match doesn't
    /// vanish the second it ends, but doesn't keep an hours-old result
    /// occupying the hero spot when an upcoming match is closer in time.
    private static let featuredWindow: TimeInterval = 2 * 60 * 60

    /// Single-card view used when a team is selected: the merino response is
    /// already scoped to that team. We don't trust the server's
    /// `previous/current/next` labels for the featured/upcoming split — those
    /// are anchored to whatever fetch date we sent (which is pinned to the
    /// tournament-window floor so the API actually returns data
    /// pre-tournament), not to the user's actual today.
    ///
    /// Bucketing rule: a match sits in `featuredMatch` (the hero) only while
    /// `now ∈ [kickoff, kickoff + featuredWindow]`. Everything else lands in
    /// `upcomingMatches` (the compact row) sorted chronologically and capped
    /// at two. If nothing is currently in the featured window, the next
    /// upcoming match is promoted so the hero never goes empty mid-tournament;
    /// if everything is past, the most recent past is promoted instead.
    ///
    /// `liveIDs` is the set of `globalEventId`s reported by the `/live`
    /// endpoint (after filtering to truly-live entries); `isLive` is set if
    /// any of this card's matches is in that set.
    init(response: WorldCupMatchesResponse,
         liveIDs: Set<Int> = [],
         now: Date = Date(),
         calendar: Calendar = .current,
         localeProvider: LocaleProvider = SystemLocaleProvider()) {
        let allMatches = (response.previous ?? []) + (response.current ?? []) + (response.next ?? [])

        var inFeaturedZone: [WorldCupMatchesResponse.Match] = []
        var others: [(date: Date, match: WorldCupMatchesResponse.Match)] = []
        for match in allMatches {
            guard let kickoff = WorldCupMatch.parseDate(match.date) else { continue }
            let windowEnd = kickoff.addingTimeInterval(Self.featuredWindow)
            if now >= kickoff && now <= windowEnd {
                inFeaturedZone.append(match)
            } else {
                others.append((kickoff, match))
            }
        }
        others.sort { $0.date < $1.date }

        var featured = inFeaturedZone
        if featured.isEmpty {
            if let idx = others.firstIndex(where: { $0.date > now }) {
                featured = [others.remove(at: idx).match]
            } else if let last = others.last {
                others.removeLast()
                featured = [last.match]
            }
        }
        let upcoming = others.prefix(2).map(\.match)

        let allIDs = allMatches.map(\.globalEventId)
        self.phaseTitle = Self.phaseTitle(from: featured.first)
        self.isLive = allIDs.contains(where: { liveIDs.contains($0) })
        self.featuredMatch = featured.map { WorldCupMatch($0, localeProvider: localeProvider) }
        self.upcomingMatches = upcoming.map { WorldCupMatch($0, localeProvider: localeProvider) }
    }

    /// Multi-card view used when no team is selected: groups every match in
    /// the response by calendar day (in `calendar`'s timezone) so each card
    /// holds all matches on the same date. Each day's matches render in the
    /// compact `upcomingMatches` row — `featuredMatch` is left empty so a
    /// crowded day doesn't blow the card up vertically. Cards are ordered
    /// chronologically (earliest day first); `defaultIndex` points at today's
    /// card, or the next future day if today has no matches.
    static func flattened(
        response: WorldCupMatchesResponse,
        liveIDs: Set<Int> = [],
        now: Date = Date(),
        calendar: Calendar = .current,
        localeProvider: LocaleProvider = SystemLocaleProvider()
    ) -> (cards: [WorldCupMatches], defaultIndex: Int) {
        let allMatches = (response.previous ?? []) + (response.current ?? []) + (response.next ?? [])
        let groups = groupedByDay(allMatches, calendar: calendar)
        // No team selected: cards can span days/stages, so we use the generic
        // group-stage label across the board. Stage-specific labels are only
        // meaningful in the team-selected single-card view.
        let title = String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel
        let cards = groups.map { group -> WorldCupMatches in
            let live = group.matches.first(where: { liveIDs.contains($0.globalEventId) })
            let featured = live.map { [WorldCupMatch($0, localeProvider: localeProvider)] } ?? []
            let upcoming = group.matches
                .filter { $0.globalEventId != live?.globalEventId }
                .map { WorldCupMatch($0, localeProvider: localeProvider) }
            return WorldCupMatches(
                phaseTitle: title,
                isLive: live != nil,
                featuredMatch: featured,
                upcomingMatches: upcoming
            )
        }
        let today = calendar.startOfDay(for: now)
        let liveCardIndex = cards.firstIndex(where: \.isLive)
        let firstFutureIndex = groups.firstIndex(where: { $0.day >= today })
        let defaultIndex = liveCardIndex ?? firstFutureIndex ?? max(cards.count - 1, 0)
        return (cards, defaultIndex)
    }

    /// Maps a featured match to a localized phase label. For group-stage
    /// matches we surface the group letter (e.g. "Group A") since both teams
    /// in a group-stage fixture share a group. For knockout matches we use
    /// the round label. Unknown or absent stages fall back to the generic
    /// "Upcoming" label so a new merino stage string doesn't blank the title.
    static func phaseTitle(from match: WorldCupMatchesResponse.Match?) -> String {
        guard let match else {
            return String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel
        }
        switch match.stage {
        case "Group Stage":
            let group = match.homeTeam.group ?? match.awayTeam.group
            return Self.groupLabel(for: group)
                ?? String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel
        case "Round of 32":
            return String.WorldCup.HomepageWidget.RoundPhase.Round32Label
        case "Round of 16":
            return String.WorldCup.HomepageWidget.RoundPhase.Round16Label
        case "Quarterfinals":
            return String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel
        case "Semifinals":
            return String.WorldCup.HomepageWidget.RoundPhase.SemiFinalsLabel
        case "Third Place":
            return String.WorldCup.HomepageWidget.RoundPhase.ThirdPlaceLabel
        case "Final":
            return String.WorldCup.HomepageWidget.RoundPhase.FinalLabel
        default:
            return String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel
        }
    }

    private static func groupLabel(for group: String?) -> String? {
        switch group {
        case "Group A": return String.WorldCup.HomepageWidget.GroupPhase.GroupA
        case "Group B": return String.WorldCup.HomepageWidget.GroupPhase.GroupB
        case "Group C": return String.WorldCup.HomepageWidget.GroupPhase.GroupC
        case "Group D": return String.WorldCup.HomepageWidget.GroupPhase.GroupD
        case "Group E": return String.WorldCup.HomepageWidget.GroupPhase.GroupE
        case "Group F": return String.WorldCup.HomepageWidget.GroupPhase.GroupF
        case "Group G": return String.WorldCup.HomepageWidget.GroupPhase.GroupG
        case "Group H": return String.WorldCup.HomepageWidget.GroupPhase.GroupH
        case "Group I": return String.WorldCup.HomepageWidget.GroupPhase.GroupI
        case "Group J": return String.WorldCup.HomepageWidget.GroupPhase.GroupJ
        case "Group K": return String.WorldCup.HomepageWidget.GroupPhase.GroupK
        case "Group L": return String.WorldCup.HomepageWidget.GroupPhase.GroupL
        default: return nil
        }
    }

    /// Groups `matches` by calendar day (using `calendar`'s timezone). Matches
    /// whose ISO date fails to parse are skipped. Returned groups are sorted
    /// by day in ascending order; within each group, matches keep their input
    /// order so equal-day matches stay in the response's chronological order.
    private static func groupedByDay(
        _ matches: [WorldCupMatchesResponse.Match],
        calendar: Calendar
    ) -> [(day: Date, matches: [WorldCupMatchesResponse.Match])] {
        var byDay: [Date: [WorldCupMatchesResponse.Match]] = [:]
        var order: [Date] = []
        for match in matches {
            guard let parsed = WorldCupMatch.parseDate(match.date) else { continue }
            let day = calendar.startOfDay(for: parsed)
            if byDay[day] == nil { order.append(day) }
            byDay[day, default: []].append(match)
        }
        return order.sorted().map { ($0, byDay[$0]!) }
    }
}
