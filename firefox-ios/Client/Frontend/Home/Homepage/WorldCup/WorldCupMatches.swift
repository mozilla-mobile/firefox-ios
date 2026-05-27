// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct WorldCupMatches: Equatable, Hashable {
    let phaseTitle: String
    let dateLabel: String?
    let isLive: Bool
    let featuredMatch: [WorldCupMatch]
    let upcomingMatches: [WorldCupMatch]

    init(phaseTitle: String,
         dateLabel: String? = nil,
         isLive: Bool,
         featuredMatch: [WorldCupMatch],
         upcomingMatches: [WorldCupMatch]) {
        self.phaseTitle = phaseTitle
        self.dateLabel = dateLabel
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
        self.dateLabel = nil
        self.isLive = allIDs.contains(where: { liveIDs.contains($0) })
        self.featuredMatch = featured.map { WorldCupMatch($0, localeProvider: localeProvider) }
        self.upcomingMatches = upcoming.map { WorldCupMatch($0, localeProvider: localeProvider) }
    }

    /// Single-team multi-card view: one card per stage the team is in (group history + one per knockout
    /// round). Each card built by `WorldCupMatches.init`; `defaultIndex` lands on the latest stage.
    static func perStage(
        response: WorldCupMatchesResponse,
        liveIDs: Set<Int> = [],
        now: Date = Date(),
        calendar: Calendar = .current,
        localeProvider: LocaleProvider = SystemLocaleProvider()
    ) -> (cards: [WorldCupMatches], defaultIndex: Int) {
        let allMatches = (response.previous ?? []) + (response.current ?? []) + (response.next ?? [])
        let dated: [(date: Date, match: WorldCupMatchesResponse.Match)] = allMatches.compactMap { match in
            WorldCupMatch.parseDate(match.date).map { ($0, match) }
        }
        guard !dated.isEmpty else {
            let empty = WorldCupMatches(
                response: response,
                liveIDs: liveIDs,
                now: now,
                calendar: calendar,
                localeProvider: localeProvider
            )
            return ([empty], 0)
        }
        let byStage = Dictionary(grouping: dated, by: { $0.match.stage })
        let sortedStages = byStage.sorted { lhs, rhs in
            let lhsDate = lhs.value.map(\.date).min() ?? .distantPast
            let rhsDate = rhs.value.map(\.date).min() ?? .distantPast
            return lhsDate < rhsDate
        }
        let cards = sortedStages.map { _, entries -> WorldCupMatches in
            // Each stage's matches are fed back through `init` as a fresh
            // response. Bucket placement (previous/current/next) doesn't
            // matter — `init` re-buckets by date against `now`.
            let stageResponse = WorldCupMatchesResponse(
                now: response.now,
                previous: nil,
                current: nil,
                next: entries.map(\.match)
            )
            return WorldCupMatches(
                response: stageResponse,
                liveIDs: liveIDs,
                now: now,
                calendar: calendar,
                localeProvider: localeProvider
            )
        }
        return (cards, max(cards.count - 1, 0))
    }

    /// No-team / eliminated-team multi-card view: group-stage matches go to per-day cards
    /// (M2 behavior); knockout matches collapse into one card per round.
    static func flattened(
        response: WorldCupMatchesResponse,
        liveIDs: Set<Int> = [],
        now: Date = Date(),
        calendar: Calendar = .current,
        localeProvider: LocaleProvider = SystemLocaleProvider()
    ) -> (cards: [WorldCupMatches], defaultIndex: Int) {
        let allMatches = (response.previous ?? []) + (response.current ?? []) + (response.next ?? [])
        let (groupMatches, knockoutByStage) = partition(allMatches)

        // Group stage: per-day cards. Title comes from the day's dominant
        // stage so unknown/nil-stage entries (the fallback bucket) read as
        // "Upcoming" rather than mis-labeling them "Group Stage".
        let groupCards = groupedByDay(groupMatches, calendar: calendar).map { group -> WorldCupMatches in
            let stageCounts = Dictionary(grouping: group.matches.compactMap(\.stage), by: { $0 })
                .mapValues(\.count)
            let dominantStage = stageCounts.max(by: { $0.value < $1.value })?.key
            return buildCard(matches: group.matches,
                             phaseTitle: label(for: dominantStage),
                             dateLabel: dayLabel(for: group.day, locale: localeProvider.current),
                             liveIDs: liveIDs,
                             localeProvider: localeProvider)
        }

        // Knockouts: per-stage cards in tournament order. Stages with no
        // matches in the response are skipped.
        let stageOrder: [WorldCupMatchesResponse.Match.Stage] = [
            .roundOf32, .roundOf16, .quarterFinals, .semiFinals, .thirdPlace, .final
        ]
        let knockoutCards = stageOrder.compactMap { stage -> WorldCupMatches? in
            guard let matches = knockoutByStage[stage], !matches.isEmpty else { return nil }
            return buildCard(matches: matches,
                             phaseTitle: label(for: stage),
                             dateLabel: nil,
                             liveIDs: liveIDs,
                             localeProvider: localeProvider)
        }

        return (groupCards + knockoutCards, 0)
    }

    /// Splits matches into group-stage entries and knockout entries
    /// keyed by stage.
    private static func partition(
        _ matches: [WorldCupMatchesResponse.Match]
    ) -> (group: [WorldCupMatchesResponse.Match],
          knockoutByStage: [WorldCupMatchesResponse.Match.Stage: [WorldCupMatchesResponse.Match]]) {
        var group: [WorldCupMatchesResponse.Match] = []
        var knockout: [WorldCupMatchesResponse.Match.Stage: [WorldCupMatchesResponse.Match]] = [:]
        for match in matches {
            switch match.stage {
            case .roundOf32, .roundOf16, .quarterFinals, .semiFinals, .thirdPlace, .final:
                knockout[match.stage!, default: []].append(match)
            case .groupStage, .unknown, .none:
                group.append(match)
            }
        }
        return (group, knockout)
    }

    private static func buildCard(
        matches: [WorldCupMatchesResponse.Match],
        phaseTitle: String,
        dateLabel: String?,
        liveIDs: Set<Int>,
        localeProvider: LocaleProvider
    ) -> WorldCupMatches {
        let liveMatches = matches.filter { liveIDs.contains($0.globalEventId) }
        let nonLive = matches.filter { !liveIDs.contains($0.globalEventId) }
        return WorldCupMatches(
            phaseTitle: phaseTitle,
            dateLabel: dateLabel,
            isLive: !liveMatches.isEmpty,
            featuredMatch: liveMatches.map { WorldCupMatch($0, localeProvider: localeProvider, timeOnly: true) },
            upcomingMatches: nonLive.map { WorldCupMatch($0, localeProvider: localeProvider, timeOnly: true) }
        )
    }

    private static func dayLabel(for day: Date, locale: Locale) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: day)
    }

    /// Maps a featured match to a localized phase label. For group-stage
    /// matches we surface the group letter (e.g. "Group A") since both teams
    /// in a group-stage fixture share a group; for everything else we
    /// delegate to the stage-only `label(for:)`. A nil match falls back to
    /// the generic group-stage label so an empty featured slot doesn't
    /// blank the title.
    static func phaseTitle(from match: WorldCupMatchesResponse.Match?) -> String {
        guard let match else {
            return String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel
        }
        if case .groupStage = match.stage {
            let group = match.homeTeam?.group ?? match.awayTeam?.group
            return Self.groupLabel(for: group)
                ?? String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel
        }
        return label(for: match.stage)
    }

    private static func label(for stage: WorldCupMatchesResponse.Match.Stage?) -> String {
        switch stage {
        case .groupStage: return String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel
        case .roundOf32: return String.WorldCup.HomepageWidget.RoundPhase.Round32Label
        case .roundOf16: return String.WorldCup.HomepageWidget.RoundPhase.Round16Label
        case .quarterFinals: return String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel
        case .semiFinals: return String.WorldCup.HomepageWidget.RoundPhase.SemiFinalsLabel
        case .thirdPlace: return String.WorldCup.HomepageWidget.RoundPhase.ThirdPlaceLabel
        case .final: return String.WorldCup.HomepageWidget.RoundPhase.FinalLabel
        case .unknown, .none: return String.WorldCup.HomepageWidget.RoundPhase.UpcomingLabel
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
