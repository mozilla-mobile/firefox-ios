// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct WorldCupMatches: Equatable, Hashable {
    let phaseTitle: String
    /// English, untranslated identifier for the card's phase, used as a stable
    /// telemetry value (e.g. "Group A", "Round of 16", "Final"). Mirrors
    /// `phaseTitle` but bypasses the localized string table.
    let telemetryPhaseValue: String
    let dateLabel: String?
    let isLive: Bool
    let featuredMatch: [WorldCupMatch]
    let upcomingMatches: [WorldCupMatch]

    /// Card fingerprint excluding live fields (scores/status). 
    /// Equal ids means refreshable in place.
    var liveAgnosticIdentity: [String] {
        func key(_ match: WorldCupMatch) -> String {
            "\(match.homeCode)|\(match.awayCode)|\(match.date)"
        }
        return [phaseTitle, winnerThirdPlaceOrFinal?.teamKey ?? ""]
            + featuredMatch.map(key)
            + upcomingMatches.map(key)
    }

    /// Returns the team key and the label for the winner of the Bronze Final or Final match.
    var winnerThirdPlaceOrFinal: (teamKey: String, winnerLabel: String)? {
        guard phaseTitle == .WorldCup.HomepageWidget.RoundPhase.FinalLabel ||
                phaseTitle == .WorldCup.HomepageWidget.RoundPhase.BronzeFinalLabel else { return nil }
        let winner = (featuredMatch + upcomingMatches).compactMap { $0.winnerKey }.first
        let label: String = phaseTitle == .WorldCup.HomepageWidget.RoundPhase.FinalLabel ?
            .WorldCup.HomepageWidget.RoundPhase.WinWorldCupLabel :
            .WorldCup.HomepageWidget.RoundPhase.ThirdPlaceLabel
        guard let winner else { return nil }
        return (winner, label)
    }

    init(phaseTitle: String,
         telemetryPhaseValue: String,
         dateLabel: String? = nil,
         isLive: Bool,
         featuredMatch: [WorldCupMatch],
         upcomingMatches: [WorldCupMatch]) {
        self.phaseTitle = phaseTitle
        self.telemetryPhaseValue = telemetryPhaseValue
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

    /// Grace period after a card's last match is estimated to be over during
    /// which the card stays selected, so a just-finished result lingers briefly
    /// before we advance to the next fixture. A live match still wins.
    private static let resultLingerWindow: TimeInterval = 30 * 60

    static func defaultIndex(in cards: [WorldCupMatches],
                             latestKickoffs: [Date],
                             now: Date) -> Int {
        guard !cards.isEmpty else { return 0 }
        if let live = cards.firstIndex(where: \.isLive) { return live }
        let window = featuredWindow + resultLingerWindow
        if let active = latestKickoffs.firstIndex(where: { now < $0.addingTimeInterval(window) }) {
            return active
        }
        return cards.count - 1
    }

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
        self.telemetryPhaseValue = Self.telemetryPhaseValue(from: featured.first)
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
        let latestKickoffs = sortedStages.map { _, entries in entries.map(\.date).max() ?? .distantPast }
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
        return (cards, defaultIndex(in: cards, latestKickoffs: latestKickoffs, now: now))
    }

    /// No-team / eliminated-team multi-card view: one card per
    /// (calendar day, stage) pair. `phaseTitle` is the card's stage,
    /// `dateLabel` is the day. Splitting on stage as well as day means
    /// the group-to-knockout transition day (last group games in the
    /// morning UTC, first R32 fixtures in the afternoon) produces two
    /// separate cards instead of mis-labeling R32 fixtures as group
    /// stage on a single mixed card.
    static func flattened(
        response: WorldCupMatchesResponse,
        liveIDs: Set<Int> = [],
        now: Date = Date(),
        calendar: Calendar = .current,
        localeProvider: LocaleProvider = SystemLocaleProvider()
    ) -> (cards: [WorldCupMatches], defaultIndex: Int) {
        let allMatches = (response.previous ?? []) + (response.current ?? []) + (response.next ?? [])
        let groups = groupedByDayAndStage(allMatches, calendar: calendar)
        let cards = groups.map { group -> WorldCupMatches in
            let liveMatches = group.matches.filter { liveIDs.contains($0.globalEventId) }
            let nonLive = group.matches.filter { !liveIDs.contains($0.globalEventId) }
            let isGroupStage = group.stage == .groupStage
            return WorldCupMatches(
                phaseTitle: label(for: group.stage),
                telemetryPhaseValue: group.stage?.rawValue ?? WorldCupMatchesResponse.Match.Stage.groupStage.rawValue,
                dateLabel: dayLabel(for: group.day, locale: localeProvider.current),
                isLive: !liveMatches.isEmpty,
                featuredMatch: liveMatches.map { WorldCupMatch($0, localeProvider: localeProvider, timeOnly: true) },
                upcomingMatches: nonLive.map { match in
                    let groupName = isGroupStage ? (match.homeTeam?.group ?? match.awayTeam?.group) : nil
                    let prefix = groupName.flatMap { groupLabel(for: $0) }
                    return WorldCupMatch(match, localeProvider: localeProvider, timeOnly: true, datePrefix: prefix)
                }
            )
        }
        let latestKickoffs = groups.map { group in
            group.matches.compactMap { WorldCupMatch.parseDate($0.date) }.max() ?? .distantPast
        }
        return (cards, defaultIndex(in: cards, latestKickoffs: latestKickoffs, now: now))
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

    static func telemetryPhaseValue(from match: WorldCupMatchesResponse.Match?) -> String {
        guard let match else { return WorldCupMatchesResponse.Match.Stage.groupStage.rawValue }
        return match.stage?.rawValue ?? WorldCupMatchesResponse.Match.Stage.groupStage.rawValue
    }

    private static func label(for stage: WorldCupMatchesResponse.Match.Stage?) -> String {
        switch stage {
        case .groupStage: return String.WorldCup.HomepageWidget.GroupPhase.GroupStageLabel
        case .roundOf32: return String.WorldCup.HomepageWidget.RoundPhase.Round32Label
        case .roundOf16: return String.WorldCup.HomepageWidget.RoundPhase.Round16Label
        case .quarterFinals: return String.WorldCup.HomepageWidget.RoundPhase.QuarterFinalsLabel
        case .semiFinals: return String.WorldCup.HomepageWidget.RoundPhase.SemiFinalsLabel
        case .thirdPlace: return String.WorldCup.HomepageWidget.RoundPhase.BronzeFinalLabel
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

    /// Returned groups are ordered by day, then by the earliest kickoff
    /// within the day (so on a group→knockout transition day, the morning
    /// group games come first and the afternoon knockout fixtures come
    /// second).
    private struct DayStageGroup {
        let day: Date
        let stage: WorldCupMatchesResponse.Match.Stage?
        let matches: [WorldCupMatchesResponse.Match]
    }

    private static func groupedByDayAndStage(
        _ matches: [WorldCupMatchesResponse.Match],
        calendar: Calendar
    ) -> [DayStageGroup] {
        struct Key: Hashable {
            let day: Date
            let stage: WorldCupMatchesResponse.Match.Stage?
        }
        var byKey: [Key: [(date: Date, match: WorldCupMatchesResponse.Match)]] = [:]
        var order: [Key] = []
        for match in matches {
            guard let parsed = WorldCupMatch.parseDate(match.date) else { continue }
            let key = Key(day: calendar.startOfDay(for: parsed), stage: match.stage)
            if byKey[key] == nil { order.append(key) }
            byKey[key, default: []].append((parsed, match))
        }
        return order
            .sorted { lhs, rhs in
                if lhs.day != rhs.day { return lhs.day < rhs.day }
                let lhsFirst = byKey[lhs]?.map(\.date).min() ?? .distantPast
                let rhsFirst = byKey[rhs]?.map(\.date).min() ?? .distantPast
                return lhsFirst < rhsFirst
            }
            .map { DayStageGroup(day: $0.day, stage: $0.stage, matches: byKey[$0]!.map(\.match)) }
    }
}
